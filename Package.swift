// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Erik",
    products: [
        .library(name: "Erik", targets: ["Erik"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", .upToNextMajor(from: "8.0.0")),
        .package(url: "https://github.com/nvzqz/FileKit.git", .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(name: "Erik", dependencies: ["Kanna", "BrightFutures"], path: "Sources"),
        .testTarget(name: "ErikTests", dependencies: ["Erik", "Kanna", "BrightFutures", "FileKit"], path: "ErikTests")
    ]
)

