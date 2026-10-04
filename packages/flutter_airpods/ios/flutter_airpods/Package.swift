// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_airpods",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "flutter-airpods", targets: ["flutter_airpods"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_airpods",
            dependencies: [],
            resources: [],
            cSettings: [
                .headerSearchPath("include/flutter_airpods")
            ]
        )
    ]
)
