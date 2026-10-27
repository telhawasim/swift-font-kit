
# Contributing to SwiftFontKit
Thank you for considering a contribution to SwiftFontKit.
Contributions may include bug fixes, tests, documentation improvements, performance improvements, accessibility improvements, and backward-compatible features.

## Before contributing
Before beginning substantial work:
1. Search existing issues and pull requests.
2. Open an issue describing the problem or proposed feature.
3. Explain the expected behavior and intended implementation.
4. Wait for confirmation when the proposed change affects public API or architecture.

Small documentation and test corrections may be submitted directly.

## Development requirements
- macOS
- Xcode 16 or later
- Swift 6 or later
- An iOS 16 or later simulator or physical device

## Getting started
Clone the repository:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/SwiftFontKit.git
cd SwiftFontKit
```

Create a branch:
```bash
git switch -c fix/descriptive-branch-name
```

Use a clear branch prefix:
```text
feature/
fix/
docs/
test/
refactor/
```

## Building

Open `Package.swift` in Xcode and select an iOS Simulator or physical iOS device.
SwiftFontKit contains UIKit integration, so testing only through a host macOS destination is insufficient.
Validate both Debug and Release configurations before submitting a pull request.

## Testing
Changes should include appropriate tests.
Test coverage should include relevant combinations of:
- Successful font loading
- Invalid font sources
- Unsupported file formats
- Invalid font data
- HTTP errors
- Download-size enforcement
- Cache integrity
- Cache corruption
- Request cancellation
- Concurrent loading
- Static fonts
- Variable fonts
- Font registration
- SwiftUI integration
- UIKit integration
- Dynamic Type
- Offline cache behavior

Avoid tests that depend unnecessarily on live network services. Prefer injected transports, deterministic fixtures, and temporary cache directories.
Tests that validate Core Text registration should use a complete, legitimately distributable font fixture together with its license.

## Code style
Follow the existing Swift style:
- Use Swift concurrency for asynchronous work.
- Maintain strict Swift 6 concurrency safety.
- Prefer immutable values.
- Avoid force unwrapping in package implementation code.
- Keep public APIs documented.
- Keep implementation details internal whenever possible.
- Use descriptive names.
- Keep methods focused.
- Preserve backward compatibility unless a breaking release is planned.
- Do not introduce third-party dependencies without prior discussion.

## Public API changes
Any new or changed public API must include:
- Documentation comments
- Usage examples
- Error behavior
- Concurrency expectations
- Tests
- Changelog entry

Breaking changes must not be included in a patch or minor release after version `1.0.0`.

## Commit messages
Use concise, imperative commit messages:
```text
Add offline cache registration test
Fix variable font weight selection
Document remote font security requirements
```

## Pull requests
A pull request should:
- Describe the problem being solved.
- Explain the implementation.
- Include relevant tests.
- Update documentation when behavior changes.
- Update `CHANGELOG.md` when appropriate.
- Build without warnings.
- Avoid unrelated formatting or refactoring.
- Keep the scope reasonably focused.

## Security issues

Do not publicly disclose suspected vulnerabilities.
Follow the private reporting instructions in [SECURITY.md](SECURITY.md).

## Font licensing
Do not commit a font fixture unless its license permits redistribution.
Every committed font fixture must include its corresponding license and attribution information.

## License
By contributing to SwiftFontKit, you agree that your contribution will be distributed under the project’s MIT License.
