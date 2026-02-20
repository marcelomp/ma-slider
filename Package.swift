// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MASlider",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "MASlider",
            targets: ["MASlider"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MASlider",
            path: "Sources",
            plugins: []),
        .testTarget(
            name: "MASliderTests", 
            dependencies: ["MASlider"], 
            path: "Tests"),
    ],
    swiftLanguageModes: [.v6]
)
