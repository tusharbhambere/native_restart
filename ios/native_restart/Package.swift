// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "native_restart",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        // If the plugin name contains "_", use "-" for the library name.
        .library(name: "native-restart", targets: ["native_restart"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "native_restart",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/native_restart",
            resources: [
                // Uncomment if a PrivacyInfo.xcprivacy is added later:
                // .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
