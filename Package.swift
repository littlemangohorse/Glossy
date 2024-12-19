// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Glossy",
	platforms: [
		.macOS(.v14), .iOS(.v17), .tvOS(.v17), .macCatalyst(.v17), .visionOS(.v1)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Glossy",
            targets: ["Glossy"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Glossy",
			resources: [.process("Blurs.metal")]
		),
    ]
)
