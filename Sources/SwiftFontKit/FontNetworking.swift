//
//  FontNetworking.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation

/// Protocol responsible for all the methods of font transport
public protocol FontTransport: Sendable {
    func get(_ url: URL, maximumBytes: Int) async throws -> Data
}

private final class HTTPSRedirectGuard: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard request.url?.scheme?.lowercased() == "https" else {
            completionHandler(nil)
            return
        }

        completionHandler(request)
    }
}

public final class LiveFontTransport: FontTransport, @unchecked Sendable {

    // MARK: - PROPERTIES -

    /// Private
    private let session: URLSession
    private let redirectGuard: HTTPSRedirectGuard

    // MARK: - INITIALIZER -
    public init() {
        let configuration = URLSessionConfiguration.ephemeral

        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let guardDelegate = HTTPSRedirectGuard()
        self.redirectGuard = guardDelegate

        self.session = URLSession(
            configuration: configuration,
            delegate: guardDelegate,
            delegateQueue: nil
        )
    }

    public func get(_ url: URL, maximumBytes: Int) async throws -> Data {
        guard url.scheme?.lowercased() == "https",
              url.host != nil else {
            throw FontKitError.invalidSource
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue("SwiftFontKit/1.0", forHTTPHeaderField: "User-Agent")

        if url.host?.lowercased() == "api.github.com" {
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        }

        let (temporaryURL, response) = try await session.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FontKitError.invalidSource
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FontKitError.httpStatus(httpResponse.statusCode)
        }

        guard httpResponse.url?.scheme?.lowercased() == "https" else {
            throw FontKitError.invalidSource
        }

        if httpResponse.expectedContentLength > Int64(maximumBytes) {
            throw FontKitError.fileTooLarge
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: temporaryURL.path)
        let actualSize = (attributes[.size] as? NSNumber)?.intValue ?? 0

        guard actualSize <= maximumBytes else {
            throw FontKitError.fileTooLarge
        }

        return try Data(contentsOf: temporaryURL)
    }
}

/// Enum responsible for font signature
enum FontSignature {
    
    /// In order to determine whether font is supported or not
    /// - Parameter data: `Data` respected data to be observed
    /// - Returns: `Bool` return `true`, if supported, otherwise `false`
    static func isSupported(_ data: Data) -> Bool {
        guard data.count >= 4 else {
            return false
        }

        let signature = Array(data.prefix(4))

        /// TrueType
        if signature == [0x00, 0x01, 0x00, 0x00] {
            return true
        }

        /// OpenType CFF
        if signature == Array("OTTO".utf8) {
            return true
        }

        return false
    }
}
