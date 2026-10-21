// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LifemartBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LifemartBar",
            path: "Sources/LifemartBar"
        )
    ],
    swiftLanguageModes: [.v5]
)
