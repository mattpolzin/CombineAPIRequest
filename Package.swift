// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineAPIRequest",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CombineAPIRequest",
            targets: ["CombineAPIRequest"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CombineAPIRequest",
            dependencies: []),
        .testTarget(
            name: "CombineAPIRequestTests",
            dependencies: ["CombineAPIRequest"]),
    ]
)
