// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreeWispr",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", revision: "c340197966ebd264f3135d3955874b40f8ed58bc"),
    ],
    targets: [
        // Core library — importable by tests
        .target(
            name: "FreeWisprCore",
            dependencies: ["SwiftWhisper"],
            path: "Sources/FreeWispr",
            exclude: ["Info.plist"],
            resources: [.copy("Resources")]
        ),
        // Executable entry point only
        .executableTarget(
            name: "FreeWispr",
            dependencies: ["FreeWisprCore"],
            path: "Sources/FreeWisprEntry"
        ),
        .testTarget(
            name: "FreeWisprTests",
            dependencies: ["FreeWisprCore"],
            path: "Tests/FreeWisprTests"
        ),
    ]
)
