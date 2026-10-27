//
//  FontDiskCache.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation
import CryptoKit

enum FontDigest {

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func sha256(_ string: String) -> String {
        sha256(Data(string.utf8))
    }
}

private struct CachedFontRecord: Codable {

    // MARK: - PROPERTIES -

    /// Normal
    let remoteURL: URL
    let fileExtension: String
    let sha256: String
}

struct FontDiskCache {

    // MARK: - PROPERTIES -

    /// Normal
    let rootDirectory: URL
    /// Computed
    private var assetsDirectory: URL {
        rootDirectory.appendingPathComponent("assets", isDirectory: true)
    }

    private var requestsDirectory: URL {
        rootDirectory.appendingPathComponent("requests", isDirectory: true)
    }

    func cachedFile(for request: FontRequest) -> URL? {
        let requestURL = metadataURL(for: request)

        guard let metadataData = try? Data(contentsOf: requestURL),
              let metadata = try? JSONDecoder().decode(CachedFontRecord.self, from: metadataData),
              ["ttf", "otf"].contains(metadata.fileExtension) else {
            return nil
        }

        let file = fontFileURL(remoteURL: metadata.remoteURL, extension: metadata.fileExtension)

        guard let data = try? Data(contentsOf: file),
              data.count <= 25_000_000,
              FontSignature.isSupported(data),
              FontDigest.sha256(data) == metadata.sha256 else {
            return nil
        }

        return file
    }

    func store(request: FontRequest, asset: FontAsset, data: Data) throws -> URL {
        let ext = URL(fileURLWithPath: asset.filename)
            .pathExtension.lowercased()

        guard ["ttf", "otf"].contains(ext) else {
            throw FontKitError.unsupportedFormat
        }

        guard data.count <= 25_000_000, FontSignature.isSupported(data) else {
            throw FontKitError.invalidFontData
        }

        do {
            let manager = FileManager.default

            try manager.createDirectory(
                at: assetsDirectory,
                withIntermediateDirectories: true
            )

            try manager.createDirectory(at: requestsDirectory, withIntermediateDirectories: true)

            let destination = fontFileURL(remoteURL: asset.remoteURL, extension: ext)

            if manager.fileExists(atPath: destination.path) {
                let existing = try Data(contentsOf: destination)

                /// Never replace a registered font file in place.
                guard existing == data else {
                    throw FontKitError.storageFailed("A cached font changed at the same source URL.")
                }
            } else {
                try data.write(to: destination, options: .atomic)
            }

            let metadata = CachedFontRecord(
                remoteURL: asset.remoteURL,
                fileExtension: ext,
                sha256: FontDigest.sha256(data)
            )

            let metadataData = try JSONEncoder().encode(metadata)

            try metadataData.write(
                to: metadataURL(for: request),
                options: .atomic
            )

            return destination
        } catch let error as FontKitError {
            throw error
        } catch {
            throw FontKitError.storageFailed(error.localizedDescription)
        }
    }
}

// MARK: - HELPER FUNCTIONS -
extension FontDiskCache {

    private func metadataURL(for request: FontRequest) -> URL {
        requestsDirectory.appendingPathComponent(FontDigest.sha256(request.cacheKey) + ".json")
    }

    private func fontFileURL(remoteURL: URL, extension ext: String) -> URL {
        let filename = FontDigest.sha256(remoteURL.absoluteString)

        return assetsDirectory.appendingPathComponent(filename + "." + ext)
    }
}
