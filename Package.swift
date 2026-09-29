// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Between",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Between", path: "Sources/Between")
    ]
)
