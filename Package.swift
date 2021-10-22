// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XSTooling",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "XSTooling",
            targets: ["XSTooling"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "XSTooling",
            dependencies: []),
        .testTarget(
            name: "XSToolingTests",
            dependencies: ["XSTooling"],
            resources: [
                .copy("Fixtures")
            ]),
    ]
)
