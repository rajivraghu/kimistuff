// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ProteinTracker",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ProteinTracker",
            targets: ["ProteinTracker"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProteinTracker",
            path: "ProteinTracker"
        ),
        .testTarget(
            name: "ProteinTrackerTests",
            dependencies: ["ProteinTracker"],
            path: "ProteinTrackerTests"
        ),
        .testTarget(
            name: "ProteinTrackerUITests",
            path: "ProteinTrackerUITests"
        )
    ]
)
