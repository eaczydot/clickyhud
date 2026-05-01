// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClickyHUD",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClickyHUD", targets: ["ClickyHUD"])
    ],
    targets: [
        .executableTarget(
            name: "ClickyHUD",
            path: "Sources/ClickyHUD"
        ),
        .testTarget(
            name: "ClickyHUDTests",
            dependencies: ["ClickyHUD"],
            path: "Tests/ClickyHUDTests"
        )
    ]
)
