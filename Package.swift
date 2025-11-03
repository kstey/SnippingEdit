// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnippingEdit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SnippingEdit",
            targets: ["SnippingEdit"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SnippingEdit",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
