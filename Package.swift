// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PowerLevel",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PowerLevel",
            path: "Sources/PowerLevel"
        )
    ]
)
