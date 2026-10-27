# SwiftFontKit
SwiftFontKit is a lightweight Swift package that downloads, caches, registers, and uses Google Fonts or remote TTF/OTF fonts at runtime.
It removes the need to manually download font files, add them to an Xcode target, or configure `UIAppFont` in `Info.plist`.

## Features
- Load fonts by Google Fonts family name
- Load fonts from Google Fonts specimen URLs
- Load remote TTF and OTF font files
- Runtime registration through Core Text
- Persistent disk caching
- SHA-256 cache integrity verification
- Concurrent request deduplication
- SwiftUI integration
- UIKit integration
- Dynamic Type support
- Variable-font weight support
- HTTPS-only networking
- Download-size and font-signature validation
- No third-party dependencies

## Requirements
- iOS 16.0+
- Swift 6.0+
- Xcode 16.0+

### Xcode
1. Open your application in Xcode.
2. Select **File → Add Package Dependencies**.
3. Enter:
```text
https://github.com/telhawasim/swift-font-kit.git
```
4. Select **Up to Next Major Version**.
5. Use `0.1.0` as the minimum version.
6. Add `SwiftFontKit` to your application target.

### Package.swift
```swift
dependencies: [
    .package(
        url: "https://github.com/telhawasim/swift-font-kit.git",
        from: "0.1.0"
    )
]
```

Add the product to your target:
```swift
.target(
    name: "YourAppTarget",
    dependencies: [
        .product(
            name: "SwiftFontKit",
            package: "swift-font-kit"
        )
    ]
)
```

## SwiftUI usage
Import SwiftFontKit:
```swift
import SwiftUI
import SwiftFontKit
```

### Google Font
```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, SwiftFontKit!")
            .googleFont(
                "Poppins",
                size: 28,
                weight: .bold,
                relativeTo: .title
            )
    }
}
```
SwiftFontKit downloads and registers the requested font when the view appears. Until loading completes, a Dynamic Type-aware system font is displayed.

### Italic font

```swift
Text("Italic text")
    .googleFont(
        "Roboto",
        size: 20,
        weight: .regular,
        style: .italic
    )
```

### Remote font

Only direct HTTPS links to TTF and OTF files are supported.

```swift
struct RemoteFontView: View {
    private let fontURL = URL(
        string: "https://example.com/fonts/MyFont-Regular.ttf"
    )!

    var body: some View {
        Text("Remote font")
            .remoteFont(
                fontURL,
                size: 22,
                weight: .regular
            )
    }
}
```

## UIKit usage

```swift
import UIKit
import SwiftFontKit

final class ViewController: UIViewController {
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Hello, SwiftFontKit!"
        view.addSubview(titleLabel)

        Task { @MainActor in
            do {
                let handle = try await SwiftFontKit.shared.load(
                    .google(
                        "Poppins",
                        weight: .bold
                    )
                )

                titleLabel.font = handle.uiFont(
                    size: 28,
                    relativeTo: .title1
                )
            } catch {
                titleLabel.font = .systemFont(
                    ofSize: 28,
                    weight: .bold
                )

                print("Font loading failed:", error)
            }
        }
    }
}
```

## Google Fonts specimen URLs

A Google Fonts specimen URL can be converted into a request:

```swift
let url = URL(
    string: "https://fonts.google.com/specimen/Poppins"
)!

let request = try FontRequest.specimen(
    url,
    weight: .semibold
)

let handle = try await SwiftFontKit.shared.load(request)
```

## Preloading fonts

Preload fonts before presenting typography-heavy screens:

```swift
let requests: [FontRequest] = [
    .google("Poppins", weight: .regular),
    .google("Poppins", weight: .semibold),
    .google("Poppins", weight: .bold),
    .google(
        "Poppins",
        weight: .regular,
        style: .italic
    )
]

do {
    try await SwiftFontKit.shared.preload(requests)
} catch {
    print("Font preloading failed:", error)
}
```
Preloading is optional. SwiftUI modifiers automatically load fonts when their views appear.

## Checking the loading state

```swift
let request = FontRequest.google(
    "Poppins",
    weight: .bold
)

let handle = try await SwiftFontKit.shared.load(request)
let isLoaded = await SwiftFontKit.shared.isLoaded(request)

print(handle.postScriptName)
print(isLoaded)
```

## Supported font weights

```swift
.thin        // 100
.extraLight  // 200
.light       // 300
.regular     // 400
.medium      // 500
.semibold    // 600
.bold        // 700
.extraBold   // 800
.black       // 900
```

## Supported styles
```swift
.normal
.italic
```

## Error handling
`SwiftFontKit.load(_:)` can throw `FontKitError`:

```swift
do {
    let handle = try await SwiftFontKit.shared.load(
        .google("Poppins", weight: .bold)
    )

    print("Loaded:", handle.postScriptName)
} catch let error as FontKitError {
    switch error {
    case .invalidSource:
        print("The font source is invalid.")

    case .unsupportedFormat:
        print("Only TTF and OTF fonts are supported.")

    case .fontNotFound(let family):
        print("Font family not found:", family)

    case .variantUnavailable(let description):
        print("Variant unavailable:", description)

    case .invalidFontData:
        print("The downloaded file is not a valid font.")

    case .fileTooLarge:
        print("The font exceeds the maximum download size.")

    case .httpStatus(let status):
        print("The server returned HTTP \(status).")

    case .registrationFailed(let reason):
        print("Font registration failed:", reason)

    case .storageFailed(let reason):
        print("Font cache failed:", reason)
    }
} catch {
    print("Unexpected error:", error)
}
```
SwiftUI modifiers intentionally retain a system-font fallback when loading fails. Use `SwiftFontKit.shared.load(_:)` directly when your application needs explicit error reporting.

## Caching
Downloaded fonts are stored under the application’s Application Support directory:

```text
Application Support/SwiftFontKit/
```

SwiftFontKit:
- Writes cached files atomically
- Validates supported font signatures
- Limits downloads to 25 MB
- Verifies cached files using SHA-256
- Registers cached fonts again when the application relaunches
- Prevents duplicate concurrent loads for the same request

Removing the application also removes its cached fonts.

## Networking and privacy
SwiftFontKit:
- Accepts HTTPS sources only
- Does not collect analytics
- Does not track users
- Does not upload application data
- Does not require an account
- Does not include advertising or telemetry SDKs

When loading a Google Font, network requests may be sent to GitHub infrastructure used by the Google Fonts repository. Direct remote-font requests are sent to the host supplied by the application developer.
Applications using SwiftFontKit should disclose remote font loading in their own privacy documentation when required.

## Font licensing
SwiftFontKit’s source code is distributed under the MIT License.
Fonts downloaded through SwiftFontKit are not covered by the SwiftFontKit license. Each font remains subject to its own license, such as:
- SIL Open Font License
- Apache License
- Ubuntu Font License
- Another license provided by the font author

Application developers are responsible for reviewing and complying with the license associated with every font they use.

## Production recommendations
For production applications:
- Preload essential fonts before displaying important screens.
- Always provide a system-font fallback.
- Test first-launch behavior without internet access.
- Test cached fonts after relaunching in airplane mode.
- Test Dynamic Type and accessibility sizes.
- Avoid relying on an uncontrolled third-party font URL.
- Confirm that every font license permits your intended usage.

## Known limitations
- Only TTF and OTF font files are supported.
- WOFF and WOFF2 files are not supported.
- Font loading requires network access on the first request.
- SwiftUI loading failures currently use the system-font fallback.
- Google Fonts catalog resolution depends on the structure and availability of the upstream Google Fonts GitHub repository.
- Runtime-downloaded fonts are registered only for the current application process.

## Contributing
Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Security
Please review [SECURITY.md](SECURITY.md) for vulnerability-reporting instructions.

## Changelog
Release history is available in [CHANGELOG.md](CHANGELOG.md).

## License
SwiftFontKit is available under the MIT License. See [LICENSE](LICENSE) for details.
