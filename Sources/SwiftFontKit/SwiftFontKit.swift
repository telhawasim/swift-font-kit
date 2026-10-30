//
//  SwiftFontKit.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation

public actor SwiftFontKit {

    // MARK: - PROPERTIES -

    /// Public
    public static let shared = SwiftFontKit()
    /// Private
    private let catalog: any FontCatalog
    private let transport: any FontTransport
    private let cache: FontDiskCache
    private var registry = FontRegistry()
    private var loadedFonts: [FontRequest: FontHandle] = [:]
    private var inFlight: [FontRequest: Task<FontHandle, Error>] = [:]
    private var inspectedFamilies: [FontSource: FontFamilyInfo] = [:]

    // MARK: - INITIALIZER -
    public init(
        catalog: (any FontCatalog)? = nil,
        transport: (any FontTransport)? = nil,
        cacheDirectory: URL? = nil
    ) {
        let selectedTransport = transport ?? LiveFontTransport()

        self.transport = selectedTransport
        self.catalog = catalog ?? GoogleFontGithubCatalog(transport: selectedTransport)

        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        self.cache = FontDiskCache(
            rootDirectory: cacheDirectory ?? applicationSupport
                .appendingPathComponent("SwiftFontKit", isDirectory: true)
        )
    }

    @discardableResult
    public func load(_ request: FontRequest) async throws -> FontHandle {
        if let handle = loadedFonts[request] {
            return handle
        }

        if let existingTask = inFlight[request] {
            return try await existingTask.value
        }

        let task = Task {
            try await performLoad(request)
        }

        inFlight[request] = task

        do {
            let handle = try await task.value

            loadedFonts[request] = handle
            inFlight[request] = nil

            return handle
        } catch {
            inFlight[request] = nil
            throw error
        }
    }

    public func preload(_ requests: [FontRequest]) async throws {
        for request in requests {
            try Task.checkCancellation()
            _ = try await load(request)
        }
    }

    public func isLoaded(_ request: FontRequest) -> Bool {
        loadedFonts[request] != nil
    }

    public func inspect(_ source: FontSource) async throws -> FontFamilyInfo {
        if let cached = inspectedFamilies[source] {
            return cached
        }

        let files: [URL]

        switch source {
        case .local(let url):
            files = [try loadLocalFile(at: url)]

        case .url(let url):
            guard url.scheme?.lowercased() == "https",
                  url.host != nil else {
                throw FontKitError.invalidSource
            }

            let ext = url.pathExtension.lowercased()
            guard ["ttf", "otf"].contains(ext) else {
                throw FontKitError.unsupportedFormat
            }

            let data = try await transport.get(url, maximumBytes: 25_000_000)

            guard FontSignature.isSupported(data) else {
                throw FontKitError.invalidFontData
            }

            files = [try cache.storeLocal(data: data, fileExtension: ext)]

        case .google(let family):
            guard let familyCatalog = catalog as? FontFamilyAssetCatalog else {
                throw FontKitError.familyInspectionUnavailable
            }

            let assets = try await familyCatalog.assets(family: family)
            var downloaded: [URL] = []

            for asset in assets {
                try Task.checkCancellation()

                let data = try await transport.get(asset.remoteURL, maximumBytes: 25_000_000)

                guard FontSignature.isSupported(data) else {
                    throw FontKitError.invalidFontData
                }

                let ext = URL(fileURLWithPath: asset.filename).pathExtension.lowercased()

                downloaded.append(try cache.storeLocal(data: data, fileExtension: ext))
            }

            files = downloaded
        }

        let inspected = try files.map {
            try FontFileInspector.inspect(fileURL: $0)
        }

        guard let first = inspected.first else {
            throw FontKitError.invalidFontData
        }

        let result = FontFamilyInfo(
            familyName: first.familyName,
            faces: inspected.flatMap(\.faces)
        )

        inspectedFamilies[source] = result
        return result
    }
}

// MARK: - HELPER FUNCTIONS -
extension SwiftFontKit {

    private func performLoad(_ request: FontRequest) async throws -> FontHandle {
        if case .local(let sourceURL) = request.source {
            let fileURL = try loadLocalFile(at: sourceURL)
            return try registry.register(fileURL: fileURL, request: request)
        }

        /// Existing cached/remote loading code follows unchanged.
        let fileURL: URL

        if let cached = cache.cachedFile(for: request) {
            fileURL = cached
        } else {
            let asset = try await resolve(request)

            try Task.checkCancellation()

            let data = try await transport.get(asset.remoteURL, maximumBytes: 25_000_000)

            try Task.checkCancellation()

            guard FontSignature.isSupported(data) else {
                throw FontKitError.invalidFontData
            }

            fileURL = try cache.store(request: request, asset: asset, data: data)
        }

        return try registry.register(fileURL: fileURL, request: request)
    }

    private func resolve(_ request: FontRequest) async throws -> FontAsset {
        switch request.source {
        case .google(let family):
            return try await catalog
                .resolve(family: family, weight: request.weight, style: request.style)

        case .url(let url):
            guard url.scheme?.lowercased() == "https",
                  url.host != nil else {
                throw FontKitError.invalidSource
            }

            let ext = url.pathExtension.lowercased()

            guard ["ttf", "otf"].contains(ext) else {
                throw FontKitError.unsupportedFormat
            }

            return FontAsset(remoteURL: url, filename: url.lastPathComponent)

        case .local:
            throw FontKitError.invalidSource
        }
    }
    
    /// In order to load the local file
    /// - Parameter sourceURL: `URL` respected url which needs to be loaded
    /// - Returns: `URL` returne the url which was retrieved
    private func loadLocalFile(at sourceURL: URL) throws -> URL {
        guard sourceURL.isFileURL else {
            throw FontKitError.invalidSource
        }

        let ext = sourceURL.pathExtension.lowercased()
        guard ["ttf", "otf"].contains(ext) else {
            throw FontKitError.unsupportedFormat
        }

        let values: URLResourceValues

        do {
            values = try sourceURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        } catch {
            throw FontKitError.invalidSource
        }

        guard values.isRegularFile == true else {
            throw FontKitError.invalidSource
        }

        if let size = values.fileSize, size > 25_000_000 {
            throw FontKitError.fileTooLarge
        }

        let data: Data

        do {
            data = try Data(contentsOf: sourceURL)
        } catch {
            throw FontKitError.invalidSource
        }

        guard data.count <= 25_000_000 else {
            throw FontKitError.fileTooLarge
        }

        guard FontSignature.isSupported(data) else {
            throw FontKitError.invalidFontData
        }

        return try cache.storeLocal(data: data, fileExtension: ext)
    }
}
