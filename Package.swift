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
    dependencies: [],
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
