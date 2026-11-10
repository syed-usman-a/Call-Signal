// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CallSignalCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "CallSignalCore", targets: ["CallSignalCore"])],
    targets: [
        .target(name: "CallSignalCore"),
        .testTarget(name: "CallSignalCoreTests", dependencies: ["CallSignalCore"])
    ]
)
