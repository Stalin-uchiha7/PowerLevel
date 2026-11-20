import Foundation
import Darwin
import AppKit
import AVFoundation

/// A process shown on the scouter, ranked by CPU.
struct Enemy: Identifiable {
    let id: pid_t
    let name: String
    let cpuPercent: Double      // share of the whole machine, 0-100 (same scale as the main power level)
    let memoryBytes: UInt64
    let startTime: UInt64       // process start (epoch seconds), guards against PID reuse before a kill
    let icon: NSImage?

    var powerLevel: Int { Int(cpuPercent * PowerScale.perPercent) }
}

/// Samples CPU, memory, thermal state and top processes every 2 seconds.
/// Uses only public Mach / libproc APIs, no root needed.
@MainActor
final class SystemMonitor: ObservableObject {
    @Published private(set) var cpuPercent: Double = 0
    @Published private(set) var memoryUsed: UInt64 = 0
    @Published private(set) var thermal: ProcessInfo.ThermalState = .nominal
    @Published private(set) var enemies: [Enemy] = []
    @Published private(set) var history: [Int] = []
    @Published var lastMessage: String?
    @Published var shoutEnabled: Bool = UserDefaults.standard.object(forKey: "shoutEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(shoutEnabled, forKey: "shoutEnabled") }
    }

    let memoryTotal = ProcessInfo.processInfo.physicalMemory
    static let historyLength = 60

    var powerLevel: Int { Int(cpuPercent * PowerScale.perPercent) }
    var form: PowerForm { PowerForm(level: powerLevel) }

    private var timer: Timer?
    private var prevTicks: (busy: UInt64, total: UInt64)?
    private var prevProcTimes: [pid_t: UInt64] = [:]
    private var prevSampleTime: UInt64 = 0
    private let speech = AVSpeechSynthesizer()
    private var lastShout = Date.distantPast
    private var wasOver9000 = false

    init() {
        sample()
        let t = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        RunLoop.main.add(t, forMode: .common)   // keep ticking while the popover is open
        timer = t
    }

    // MARK: - Sampling

    private func sample() {
        if let ticks = Self.cpuTicks() {
            if let prev = prevTicks, ticks.total > prev.total, ticks.busy >= prev.busy {
                cpuPercent = Double(ticks.busy - prev.busy) / Double(ticks.total - prev.total) * 100
            }
            prevTicks = ticks
        }
        memoryUsed = Self.memoryUsed()
        thermal = ProcessInfo.processInfo.thermalState
        sampleEnemies()

        history.append(powerLevel)
        if history.count > Self.historyLength {
            history.removeFirst(history.count - Self.historyLength)
        }
        checkOver9000()
    }

    private static func cpuTicks() -> (busy: UInt64, total: UInt64)? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        let user = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2)
        let nice = UInt64(info.cpu_ticks.3)
        return (user + system + nice, user + system + idle + nice)
    }

    /// Same formula as Activity Monitor's "Memory Used": app memory + wired + compressed.
    private static func memoryUsed() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        let page = UInt64(vm_kernel_page_size)
        let appPages = UInt64(stats.internal_page_count)
        let purgeable = UInt64(stats.purgeable_count)
        let app = appPages > purgeable ? appPages - purgeable : 0
        return (app + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * page
    }

    private func sampleEnemies() {
        let now = mach_absolute_time()
        let wall = prevSampleTime > 0 ? now - prevSampleTime : 0

        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let found = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard found > 0 else { return }

        let cores = Double(max(ProcessInfo.processInfo.activeProcessorCount, 1))
        var times: [pid_t: UInt64] = [:]
        var ranked: [(pid: pid_t, cpu: Double, mem: UInt64)] = []

        for pid in pids.prefix(Int(found)) where pid > 0 {
            var info = rusage_info_v2()
            let rc = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V2, $0)
                }
            }
            guard rc == 0 else { continue }
            // CPU time and mach_absolute_time share units on both Intel and Apple Silicon,
            // so the ratio is the CPU share without a timebase conversion.
            let cpuTime = info.ri_user_time + info.ri_system_time
            times[pid] = cpuTime
            if wall > 0, let prev = prevProcTimes[pid], cpuTime >= prev {
                ranked.append((pid, Double(cpuTime - prev) / Double(wall) * 100 / cores, info.ri_phys_footprint))
            }
        }
        prevProcTimes = times
        prevSampleTime = now

        enemies = ranked
            .sorted { $0.cpu > $1.cpu }
            .prefix(6)
            .map { entry in
                let app = NSRunningApplication(processIdentifier: entry.pid)
                return Enemy(
                    id: entry.pid,
                    name: app?.localizedName ?? Self.processName(entry.pid),
                    cpuPercent: entry.cpu,
                    memoryBytes: entry.mem,
                    startTime: Self.startTime(entry.pid),
                    icon: app?.icon)
            }
    }

    private static func processName(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        if proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 {
            return (String(cString: buffer) as NSString).lastPathComponent
        }
        return "pid \(pid)"
    }

    private static func startTime(_ pid: pid_t) -> UInt64 {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return 0 }
        return info.pbi_start_tvsec
    }

    // MARK: - IT'S OVER 9000

    private func checkOver9000() {
        let over = powerLevel > PowerScale.over9000
        if over, !wasOver9000, shoutEnabled, Date().timeIntervalSince(lastShout) > 120 {
            lastShout = Date()
            let utterance = AVSpeechUtterance(string: "It's over nine thousand!")
            utterance.rate = 0.55
            utterance.pitchMultiplier = 1.3
            speech.speak(utterance)
        }
        wasOver9000 = over
    }

    // MARK: - Ki blast (terminate a process)

    /// Never signalled: killing these logs you out or hangs macOS.
    private static let untouchable: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "loginwindow", "opendirectoryd",
        "securityd", "configd", "coreservicesd",
    ]

    func blast(_ enemy: Enemy, force: Bool) {
        guard enemy.id > 1, enemy.id != getpid() else {
            lastMessage = "\(enemy.name) can't be defeated."
            return
        }
        guard !Self.untouchable.contains(Self.processName(enemy.id)) else {
            lastMessage = "\(enemy.name) holds the universe together. Leave it."
            return
        }
        guard enemy.startTime != 0, Self.startTime(enemy.id) == enemy.startTime else {
            lastMessage = "\(enemy.name) already left the battlefield."
            return
        }
        if kill(enemy.id, force ? SIGKILL : SIGTERM) == 0 {
            lastMessage = force ? "\(enemy.name) was obliterated." : "Ki blast hit \(enemy.name)."
        } else if errno == EPERM {
            lastMessage = "\(enemy.name) is too strong (system process)."
        } else {
            lastMessage = "\(enemy.name) dodged: \(String(cString: strerror(errno)))"
        }
    }
}
