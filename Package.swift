// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Procedure",
    products: [
        .library(
            name: "Procedure",
            targets: ["Procedure"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Procedure",
            dependencies: []),
        .testTarget(
            name: "ProcedureTests",
            dependencies: ["Procedure"]),
    ],
    swiftLanguageVersions: [.v5]
)
