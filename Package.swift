// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftZSTD",
    products: [
        .library(
            name: "SwiftZSTD",
            targets: ["SwiftZSTD", "zstdlib"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftZSTD",
            dependencies: ["zstdlib"]),
        .target(
            name: "zstdlib",
            dependencies: [],
            exclude: ["LICENSE"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("common"),
                .headerSearchPath("compress"),
                .headerSearchPath("decompress"),
                .headerSearchPath("dictBuilder"),
                .headerSearchPath("include/zstdlib")
            ]),
        .testTarget(
            name: "SwiftZSTDTests",
            dependencies: ["SwiftZSTD"]),
    ]
)
