# Power Level

A Dragon Ball Z–themed macOS menu bar app. Your Mac's CPU load is its **power level**, shown scouter-style in the menu bar.

Native Swift/SwiftUI, no third-party dependencies, no root. Needs macOS 14+.

## What it shows

| Scouter reading | What it means on the Mac |
|---|---|
| Power level | CPU % × 120 (100% CPU = 12,000) |
| "It's over 9000!" | Spoken out loud when CPU passes 75% (off by default; turn on "Shout at 9000" in the popover; at most once every 2 minutes) |
| Ki | CPU usage |
| Stamina | RAM used / total (Activity Monitor's formula) |
| Ki Heat | macOS thermal state (Calm → Warm → Overheating → Meltdown) |
| Enemies detected | Top 6 processes by CPU, each with its own power level |
| Blast / Force | Quit a process (SIGTERM) / force kill it (SIGKILL, after a second click) |

### Forms

| Power level | CPU | Form |
|---|---|---|
| 0 – 999 | < 8% | Base Form |
| 1,000 – 2,999 | 8–25% | Kaioken |
| 3,000 – 5,999 | 25–50% | Super Saiyan |
| 6,000 – 9,000 | 50–75% | Super Saiyan 2 |
| 9,001+ | > 75% | **IT'S OVER 9000!** |

Each form has its own menu bar icon, and the popover shows an original mascot, drawn in code, whose pose, face, crest and aura change with the form.

## Build and run

Needs the Xcode Command Line Tools (`xcode-select --install`).

```bash
swift run                      # quick dev run
./scripts/build-app.sh         # builds build/PowerLevel.app (ad-hoc signed)
open build/PowerLevel.app
```

To start it at login, add `PowerLevel.app` in **System Settings → General → Login Items**.

## How it works

Everything comes from public macOS APIs, so the app never asks for a password:

- CPU: `host_statistics(HOST_CPU_LOAD_INFO)`
- RAM: `host_statistics64(HOST_VM_INFO64)`
- Per-process CPU and memory: `proc_listallpids` + `proc_pid_rusage` (your own processes only)
- Heat: `ProcessInfo.thermalState`
- Voice: `AVSpeechSynthesizer`

Blast and Force only work on your own processes. The app refuses to signal core macOS processes, and re-checks the process start time before a kill so a reused PID is never hit.

## Roadmap

- Hyperbolic Time Chamber: a focus timer that earns "training XP"
- Senzu beans: battery shown as beans, with an alert on the last one
- Battle log: daily "strongest enemy" history
- Sound effects and original sprite art

## Credits

Inspired by [MacLens](https://github.com/amrakshay/maclens).

This is an unofficial fan project. It is not affiliated with or endorsed by the owners of Dragon Ball. It ships no official artwork, audio or characters: only text, colours and SF Symbols.

## License

[MIT](LICENSE)
