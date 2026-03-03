// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HabitTracker",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HabitTracker",
            targets: ["HabitTracker"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HabitTracker",
            path: "HabitTracker"
        ),
        .testTarget(
            name: "HabitTrackerTests",
            dependencies: ["HabitTracker"],
            path: "HabitTrackerTests"
        ),
        .testTarget(
            name: "HabitTrackerUITests",
            path: "HabitTrackerUITests"
        )
    ]
)
