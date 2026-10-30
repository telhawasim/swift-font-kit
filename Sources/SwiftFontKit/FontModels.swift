//
//  FontModels.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation

/// Protocol responsible for any type of font catalog
public protocol FontCatalog: Sendable {
    func resolve(family: String, weight: FontWeight, style: FontStyle) async throws -> FontAsset
}

/// Protocol responsible for any type of font family asset catalog
public protocol FontFamilyAssetCatalog: FontCatalog {
    func assets(family: String) async throws -> [FontAsset]
}

/// Enum responsible for all types of font weight
public enum FontWeight: Int, Codable, Sendable, CaseIterable {
    case thin = 100
    case extraLight = 200
    case light = 300
    case regular = 400
    case medium = 500
    case semibold = 600
    case bold = 700
    case extraBold = 800
    case black = 900

    // MARK: - PROPERTIES -

    /// Computed
    var fileSuffix: String {
        switch self {
        case .thin: "Thin"
        case .extraLight: "ExtraLight"
        case .light: "Light"
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .extraBold: "ExtraBold"
        case .black: "Black"
        }
    }
}

/// Enum responsible for all types of font style
public enum FontStyle: String, Codable, Sendable {
    case normal
    case italic
}

/// Enum responsible for all types of font sources
public enum FontSource: Hashable, Sendable {
    case google(String)
    case url(URL)
    case local(URL)
}

/// Enum responsible for all types of font kit error
public enum FontKitError: Error, LocalizedError, Sendable {
    case invalidSource
    case unsupportedFormat
    case fontNotFound(String)
    case variantUnavailable(String)
    case invalidFontData
    case fileTooLarge
    case httpStatus(Int)
    case registrationFailed(String)
    case storageFailed(String)
    case familyInspectionUnavailable

    // MARK: - PROPERTIES -

    /// Computed
    public var errorDescription: String? {
        switch self {
        case .invalidSource:
            "Invalid font URL or family."

        case .unsupportedFormat:
            "Only HTTPS TTF and OTF font files are supported."

        case .fontNotFound(let family):
            "Font family not found: \(family)"

        case .variantUnavailable(let message):
            "Requested font variant is unavailable: \(message)"

        case .invalidFontData:
            "Downloaded file is not a valid supported font."

        case .fileTooLarge:
            "Font exceeds the permitted download size."

        case .httpStatus(let status):
            "Font server returned HTTP \(status)"

        case .registrationFailed(let reason):
            "Core Text registration failed: \(reason)"

        case .storageFailed(let reason):
            "Font cache failed: \(reason)"

        case .familyInspectionUnavailable:
            "This font catalog does not support family inspection."
        }
    }
}

/// Model responsible for any type of font request
public struct FontRequest: Hashable, Sendable {

    // MARK: - PROPERTIES -

    /// Public
    public let source: FontSource
    public let weight: FontWeight
    public let style: FontStyle
    /// Internal
    internal var cacheKey: String {
        let sourceKey: String

        switch source {
        case .google(let family):
            sourceKey = "google:" + family
                .lowercased()
                .filter { $0.isLetter || $0.isNumber }

        case .url(let url):
            sourceKey = "url:" + url.absoluteString

        case .local(let url):
            sourceKey = "local:" + url.standardizedFileURL.path
        }

        return "\(sourceKey):\(weight.rawValue):\(style.rawValue)"
    }

    // MARK: - INITIALIZER -
    public init(source: FontSource, weight: FontWeight = .regular, style: FontStyle = .normal) {
        self.source = source
        self.weight = weight
        self.style = style
    }
    
    /// In order to handle the font using google
    /// - Parameters:
    ///   - family: `String` respected font family name
    ///   - weight: `FontWeight` respected font weight of the font
    ///   - style: `FontStyle` respected font style of the font
    /// - Returns: `Self` will return the font after proper configuration
    public static func google(
        _ family: String,
        weight: FontWeight = .regular,
        style: FontStyle = .normal
    ) -> Self {
        Self(source: .google(family), weight: weight, style: style)
    }
    
    /// In order to handle the font using remote source
    /// - Parameters:
    ///   - url: `URL` repected link for the foot
    ///   - weight: `FontWeight` respected font weight of the font
    ///   - style: `FontStyle` respected font style of the font
    /// - Returns: `Self` will return the font after proper configuration
    public static func remote(
        _ url: URL,
        weight: FontWeight = .regular,
        style: FontStyle = .normal
    ) -> Self {
        Self(source: .url(url), weight: weight, style: style)
    }
    
    /// In order to handle the font using custom specimen
    /// - Parameters:
    ///   - url: `URL` respected link for the foot
    ///   - weight: `FontWeight` respected font weight of the font
    ///   - style: `FontStyle` respected font style of the font
    /// - Returns: `Self` will return the font after proper configuration
    public static func specimen(
        _ url: URL,
        weight: FontWeight = .regular,
        style: FontStyle = .normal
    ) throws -> Self {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "fonts.google.com",
              url.pathComponents.count == 3,
              url.pathComponents[1] == "specimen" else {
            throw FontKitError.invalidSource
        }

        let family = url.lastPathComponent
            .replacingOccurrences(of: "+", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !family.isEmpty else {
            throw FontKitError.invalidSource
        }

        return .google(family, weight: weight, style: style)
    }
    
    /// In order to handle the local font
    /// - Parameters:
    ///   - fileURL: `URL` respected local url
    ///   - weight: `FontWeight` respected font weight of the font
    ///   - style: `FontStyle` respected font style of the font
    /// - Returns: `Self` will return the font after proper configuration
    public static func local(
        _ fileURL: URL,
        weight: FontWeight = .regular,
        style: FontStyle = .normal
    ) -> Self {
        Self(source: .local(fileURL.standardizedFileURL), weight: weight, style: style)
    }
    
    /// In order to find a font included in the application or Swift package source bundle
    /// - Parameters:
    ///   - fileName: `String` file name for the font
    ///   - bundle: `Bundle` local application bundle which is `main`
    ///   - weight: `FontWeight` respected font weight
    ///   - style: `FontStyle` respected font style
    /// - Returns: `Self` will return the font after proper configuration
    public static func bundled(
        _ fileName: String,
        in bundle: Bundle = .main,
        weight: FontWeight = .regular,
        style: FontStyle = .normal
    ) throws -> Self {
        let file = fileName as NSString
        let name = file.deletingPathExtension
        let ext = file.pathExtension.lowercased()

        guard file.lastPathComponent == fileName,
              !name.isEmpty,
              ["ttf", "otf"].contains(ext) else {
            throw FontKitError.invalidSource
        }

        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw FontKitError.fontNotFound(fileName)
        }

        return .local(url, weight: weight, style: style)
    }
}

/// Model responsible for any type of font asset
public struct FontAsset: Sendable {

    // MARK: - PROPERTIES -

    /// Public
    public let remoteURL: URL
    public let filename: String
    public let licenseURL: URL?

    // MARK: - INITIALIZER -
    public init(remoteURL: URL, filename: String, licenseURL: URL? = nil) {
        self.remoteURL = remoteURL
        self.filename = filename
        self.licenseURL = licenseURL
    }
}

/// Model responsible for any type of font handling
public struct FontHandle: Sendable {

    // MARK: - PROPERTIES -

    /// Public
    public let postScriptName: String
    public let familyName: String
    public let weight: FontWeight
    public let style: FontStyle
    public let weightAxisIdentifier: UInt32?

    // MARK: - INITIALIZER -
    public init(
        postScriptName: String,
        familyName: String,
        weight: FontWeight,
        style: FontStyle,
        weightAxisIdentifier: UInt32?
    ) {
        self.postScriptName = postScriptName
        self.familyName = familyName
        self.weight = weight
        self.style = style
        self.weightAxisIdentifier = weightAxisIdentifier
    }
}
