// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MASlider",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "MASlider", 
            targets: ["MASlider"]),
    ],
    targets: [
        .target(
            name: "MASlider", 
            path: "Sources"),
        .testTarget(
            name: "MASliderTests", 
            dependencies: ["MASlider"], 
            path: "Tests"),
    ],
    swiftLanguageModes: [.v6]
)
