// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftFontKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "SwiftFontKit",
            targets: ["SwiftFontKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/telhawasim/swift-font-kit", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "SwiftFontKit",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftFontKitTests",
            dependencies: ["SwiftFontKit"],
        ),
    ],
    swiftLanguageModes: [.v6]
)
