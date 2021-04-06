// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PRAssigner",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "PRAssigner", targets: ["PRAssigner"]),
        .library(name: "PRAssignerCore", targets: ["PRAssignerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.2.0")),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.4")
    ],
    targets: [
        .target(
            name: "PRAssignerCore",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "SotoSecretsManager", package: "soto"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Yams", package: "Yams")]
        ),
        .target(
            name: "PRAssigner",
            dependencies: ["PRAssignerCore"]),
        .testTarget(
            name: "PRAssignerCoreTests",
            dependencies: ["PRAssignerCore"],
            exclude: ["Resources/test-event.json"])
    ]
)
