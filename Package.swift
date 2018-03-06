// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ArgParse",
    products: [
        .library(name: "ArgParse", targets: ["ArgParse"]),
    ],
    targets: [
        .target(name: "ArgParse", dependencies: []),
        .testTarget(name: "ArgParseTests", dependencies: ["ArgParse"]),
    ]
)
