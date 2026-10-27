
# Security Policy
Security is important to SwiftFontKit because the package downloads, validates, stores, and registers remote font files.

## Supported versions
During the initial public-preview period, security updates are provided only for the most recent release.

| Version | Supported |
|---|---|
| Latest `0.x` release | Yes |
| Older `0.x` releases | No |

The supported-version policy may change after SwiftFontKit reaches version `1.0.0`.

## Reporting a vulnerability
Please do not report security vulnerabilities through a public GitHub issue, discussion, or pull request.
Report vulnerabilities privately using GitHub Private Vulnerability Reporting:
1. Open the SwiftFontKit GitHub repository.
2. Select the **Security** tab.
3. Select **Report a vulnerability**.
4. Provide the requested technical details.

If private vulnerability reporting is unavailable, contact the maintainer privately through the contact method listed on the maintainer’s GitHub profile.

## Information to include
Include as much of the following information as possible:
- A clear description of the vulnerability
- Affected SwiftFontKit version
- Affected iOS version
- Xcode and Swift versions
- Reproduction steps
- Proof-of-concept code
- Expected behavior
- Actual behavior
- Potential impact
- Suggested mitigation, if known
- Whether the vulnerability has been publicly disclosed

## Response process
After receiving a report, the maintainer will attempt to:
1. Acknowledge the report.
2. Reproduce and assess the issue.
3. Determine affected versions.
4. Prepare and test a correction.
5. Coordinate disclosure with the reporter.
6. Publish a security release and advisory when appropriate.

Response and resolution times depend on the severity and complexity of the report.

## Security boundaries
SwiftFontKit includes protections such as:
- HTTPS-only source validation
- Redirect scheme validation
- Download-size limits
- TTF and OTF extension restrictions
- Font-signature validation
- SHA-256 cache integrity verification
- Atomic cache writes
- Core Text descriptor validation
- Process-scoped font registration

These protections reduce risk but do not guarantee that every remotely hosted font is safe, trustworthy, correctly licensed, or permanently available.
Applications should load fonts only from trusted sources.

## Out-of-scope reports
The following are generally not considered SwiftFontKit vulnerabilities:
- An upstream font host becoming unavailable
- A font being removed or renamed upstream
- General GitHub API rate limiting
- A font displaying differently across iOS versions
- A font license dispute unrelated to SwiftFontKit code
- Attacks requiring a deliberately modified application binary
- Unsupported font formats being rejected as documented

## Disclosure
Please allow reasonable time for investigation and remediation before publicly disclosing a vulnerability.
