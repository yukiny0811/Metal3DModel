// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Metal3DModel",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Metal3DModel",
            targets: ["Metal3DModel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/yukiny0811/MetalVertexHelper", .upToNextMajor(from: "1.0.2")),
    ],
    targets: [
        .target(
            name: "Metal3DModel",
            dependencies: [
                .product(name: "MetalVertexHelper", package: "MetalVertexHelper"),
            ]
        ),
    ]
)
