// swift-tools-version:6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "XSTooling",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "XSTooling",
            targets: ["XSTooling"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "XSTooling",
            dependencies: [],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "XSToolingTests",
            dependencies: ["XSTooling"],
            resources: [
                .copy("Fixtures")
            ],
            swiftSettings: swiftSettings),
    ],
    swiftLanguageModes: [.v6],
)
