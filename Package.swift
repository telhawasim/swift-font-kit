// swift-tools-version: 6.4

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
