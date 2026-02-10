// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "multicodex-macos",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "MultiCodexMenu", targets: ["MultiCodexMenu"]),
    ],
    targets: [
        .executableTarget(
            name: "MultiCodexMenu",
            path: "Sources/MultiCodexMenu",
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
