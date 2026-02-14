// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "zelerK",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "zelerK",
            path: "Sources/Zelerk"
        )
    ]
)
