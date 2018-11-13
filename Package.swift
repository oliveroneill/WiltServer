// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WiltServer",
    products: [
        .executable(name: "WiltServer", targets: ["WiltServer"]),
        .library(name: "WiltLib", targets: ["WiltLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/oliveroneill/HexavilleFramework.git", .branch("master")),
        .package(url: "https://github.com/noahemmet/Graphiti.git", .branch("master")),
        .package(url: "https://github.com/swift-aws/dynamodb.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(name: "WiltServer", dependencies: ["HexavilleFramework", "WiltLib"]),
        .target(name: "WiltLib", dependencies: ["Graphiti", "SwiftAWSDynamodb"]),
        .testTarget(
            name: "WiltLibTests",
            dependencies: ["WiltLib"]),
    ]
)
