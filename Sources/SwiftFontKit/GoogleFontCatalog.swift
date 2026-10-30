//
//  GoogleFontCatalog.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation

struct GithubEntry: Decodable, Sendable {
    let name: String
    let type: String
    let downloadURL: URL?

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case downloadURL = "download_url"
    }
}

public struct GoogleFontGithubCatalog: FontFamilyAssetCatalog {

    // MARK: - PROPERTIES -

    /// Private
    private let transport: any FontTransport

    // MARK: - INITIALIZER -
    public init(transport: any FontTransport = LiveFontTransport()) {
        self.transport = transport
    }

    public func resolve(
        family: String,
        weight: FontWeight,
        style: FontStyle
    ) async throws -> FontAsset {
        let slug = family.lowercased()
            .unicodeScalars
            .filter {
                CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains($0)
            }
            .map(String.init)
            .joined()

        guard !slug.isEmpty, slug.count <= 100 else {
            throw FontKitError.invalidSource
        }

        var rootPath: String?
        var rootEntries: [GithubEntry] = []

        for licenseDirectory in ["ofl", "apache", "ufl"] {
            let path = "\(licenseDirectory)/\(slug)"

            do {
                let entries = try await fetchEntries(path: path)

                rootPath = path
                rootEntries = entries
                break
            } catch FontKitError.httpStatus(404) {
                continue
            }
        }

        guard let rootPath else {
            throw FontKitError.fontNotFound(family)
        }

        let licenseURL = rootEntries.first {
            ["OFL.TXT", "LICENSE.TXT", "UFL.TXT", "LICENSE"]
                .contains($0.name.uppercased())
        }?.downloadURL

        /// Prefer an exact static font, when available.
        var allFiles = rootEntries

        if rootEntries.contains(where: {
            $0.type == "dir" && $0.name == "static"
        }) {
            let staticFiles = try await fetchEntries(path: rootPath + "/static")

            allFiles.append(contentsOf: staticFiles)
        }

        guard let selected = Self.select(from: allFiles, weight: weight, style: style) else {
            throw FontKitError.variantUnavailable(
                "\(family) \(weight.rawValue) \(style.rawValue)"
            )
        }

        guard let url = selected.downloadURL,
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "raw.githubusercontent.com" else {
            throw FontKitError.invalidSource
        }

        return FontAsset(remoteURL: url, filename: selected.name, licenseURL: licenseURL)
    }

    public func assets(family: String) async throws -> [FontAsset] {
        let slug = family.lowercased()
            .unicodeScalars
            .filter {
                CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains($0)
            }
            .map(String.init)
            .joined()

        guard !slug.isEmpty, slug.count <= 100 else {
            throw FontKitError.invalidSource
        }

        var rootPath: String?
        var entries: [GithubEntry] = []

        for licenseDirectory in ["ofl", "apache", "ufl"] {
            let path = "\(licenseDirectory)/\(slug)"

            do {
                entries = try await fetchEntries(path: path)
                rootPath = path
                break
            } catch FontKitError.httpStatus(404) {
                continue
            }
        }

        guard let rootPath else {
            throw FontKitError.fontNotFound(family)
        }

        if entries.contains(where: { $0.type == "dir" && $0.name == "static" }) {
            entries += try await fetchEntries(path: rootPath + "/static")
        }

        let assets = entries.compactMap { entry -> FontAsset? in
            guard entry.type == "file",
                  ["ttf", "otf"].contains(
                    URL(fileURLWithPath: entry.name).pathExtension.lowercased()
                  ),
                  let url = entry.downloadURL,
                  url.scheme?.lowercased() == "https",
                  url.host?.lowercased() == "raw.githubusercontent.com" else {
                return nil
            }

            return FontAsset(remoteURL: url, filename: entry.name)
        }

        guard !assets.isEmpty else {
            throw FontKitError.fontNotFound(family)
        }

        return assets.sorted { $0.filename < $1.filename }
    }
}

// MARK: - HELPER FUNCTIONS -
extension GoogleFontGithubCatalog {

    private func fetchEntries(path: String) async throws -> [GithubEntry] {
        guard let url = URL(
            string: "https://api.github.com/repos/google/fonts/contents/\(path)?ref=main"
        ) else {
            throw FontKitError.invalidSource
        }

        let data = try await transport.get(url, maximumBytes: 2_000_000)

        return try JSONDecoder().decode([GithubEntry].self, from: data)
    }

    static func select(
        from entries: [GithubEntry],
        weight: FontWeight,
        style: FontStyle
    ) -> GithubEntry? {
        let files = entries
            .filter {
                $0.type == "file" &&
                ["ttf", "otf"].contains(
                    URL(fileURLWithPath: $0.name).pathExtension.lowercased()
                )
            }
            .sorted { $0.name < $1.name }

        let staticFiles = files.filter {
            !$0.name.contains("[")
        }

        let suffix = weight.fileSuffix.lowercased() + (style == .italic ? "italic" : "")

        if let exact = staticFiles.first(where: { entry in
            let base = (entry.name as NSString)
                .deletingPathExtension
                .lowercased()

            if base.hasSuffix("-" + suffix) {
                return true
            }

            if weight == .regular && style == .italic {
                return base.hasSuffix("-italic")
            }

            if weight == .regular && style == .normal {
                return !base.contains("-")
            }

            return false
        }) {
            return exact
        }

        /// Fallback to a variable font containing a wght axis.
        let variables = files.filter {
            $0.name.contains("[")
        }

        return variables.first(where: { entry in
            let name = entry.name.lowercased()
            let isItalic = name.contains("italic")

            guard isItalic == (style == .italic) else {
                return false
            }

            return name.contains("wght")
        })
    }
}
