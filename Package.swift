// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CubeColorPicker",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "CubeColorPicker",
            targets: ["CubeColorPicker"]
        ),
    ],
    targets: [
        .target(
            name: "CubeColorPicker",
            path: "Sources/CubeColorPicker"
        ),
        .testTarget(
            name: "CubeColorPickerTests",
            dependencies: ["CubeColorPicker"],
            path: "Tests/CubeColorPickerTests"
        ),
    ]
)
