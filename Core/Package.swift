// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RTXOnCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RTXOnCore", targets: ["RTXOnCore"]),
    ],
    targets: [
        .target(name: "RTXOnCore"),
        .testTarget(name: "RTXOnCoreTests", dependencies: ["RTXOnCore"]),
    ]
)
