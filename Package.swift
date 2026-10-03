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
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "XSTooling",
            targets: ["XSTooling"])
    ],
    traits: [
        .trait(
            name: "EnableSubprocess",
            description: "Enable swift-subprocess dependency"
        ),
        // .default(enabledTraits: ["EnableSubprocess"]), // Local Development
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "XSTooling",
            dependencies: [
                .product(
                    name: "Subprocess",
                    package: "swift-subprocess",
                    condition: .when(traits: ["EnableSubprocess"])
                ),
            ],
            swiftSettings: swiftSettings,
        ),
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
