//
//  FontFamilyInspection.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 30/10/2026.
//

import Foundation
import CoreText

/// Model responsible for one axis exposed by a variable font
public struct FontAxisInfo: Sendable {

    // MARK: - PROPERTIES -

    /// Normal
    public let identifier: UInt32
    public let name: String
    public let minimum: Double
    public let defaultValue: Double
    public let maximum: Double
}

/// Model responsible for one font file or face within a family
public struct FontFaceInfo: Sendable {

    // MARK: - PROPERTIES -

    /// Normal
    public let postScriptName: String
    public let style: FontStyle
    public let nomialWeight: Int
    public let availableWeights: [FontWeight]
    public let variableAxes: [FontAxisInfo]
    /// Computed
    public var isVariable: Bool {
        !variableAxes.isEmpty
    }
}

/// Model responsible for information suitable for displaying a family in a font picker
public struct FontFamilyInfo: Sendable {

    // MARK: - PROPERTIES -

    /// Normal
    public let familyName: String
    public let faces: [FontFaceInfo]
    /// Computed
    public var availableWeights: [FontWeight] {
        FontWeight.allCases.filter { weight in
            faces.contains { $0.availableWeights.contains(weight) }
        }
    }

    public var availableStyles: [FontStyle] {
        [.normal, .italic].filter { style in
            faces.contains { $0.style == style }
        }
    }
}

/// Enum responsible for all font file inspecptor
enum FontFileInspector {

    // MARK: - PROPERTIES -

    /// Private
    private static let weightAxisTag: UInt32 = 0x77676874

    static func inspect(fileURL: URL) throws -> FontFamilyInfo {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fileURL as CFURL) as? [CTFontDescriptor],
              !descriptors.isEmpty else {
            throw FontKitError.invalidFontData
        }

        /// Read the OS/2 weight once for a static font.
        let data = try Data(contentsOf: fileURL)
        let staticWeight = try readOS2Weight(from: data)
        let fonts = descriptors.map {
            CTFontCreateWithFontDescriptor($0, 14, nil)
        }

        guard let first = fonts.first else {
            throw FontKitError.invalidFontData
        }

        let familyName = CTFontCopyFamilyName(first) as String
        let faces = fonts.map { font -> FontFaceInfo in
            let axes = variableAxes(in: font)
            let weightAxes = axes.first { $0.identifier == weightAxisTag }
            let weights: [FontWeight]
            let nominalWeight: Int

            if let weightAxes {
                weights = FontWeight.allCases.filter {
                    let value = Double($0.rawValue)
                    return value >= weightAxes.minimum && value <= weightAxes.maximum
                }
                nominalWeight = Int(weightAxes.defaultValue.rounded())
            } else {
                weights = FontWeight.allCases.filter {
                    $0.rawValue == staticWeight
                }
                nominalWeight = staticWeight
            }

            let traits = CTFontGetSymbolicTraits(font)

            return FontFaceInfo(
                postScriptName: CTFontCopyPostScriptName(font) as String,
                style: traits.contains(.traitItalic) ? .italic : .normal,
                nomialWeight: nominalWeight,
                availableWeights: weights,
                variableAxes: axes
            )
        }

        return FontFamilyInfo(familyName: familyName, faces: faces)
    }

    private static func variableAxes(in font: CTFont) -> [FontAxisInfo] {
        guard let rawAxes = CTFontCopyVariationAxes(font) as? [[String: Any]] else {
            return []
        }

        return rawAxes.compactMap { axis in
            guard let identifier = axis[kCTFontVariationAxisIdentifierKey as String] as? NSNumber,
                  let minimum = axis[kCTFontVariationAxisMinimumValueKey as String] as? NSNumber,
                  let defaultValue = axis[kCTFontVariationAxisDefaultValueKey as String] as? NSNumber,
                  let maximum = axis[kCTFontVariationAxisMaximumValueKey as String] as? NSNumber else {
                return nil
            }

            return FontAxisInfo(
                identifier: identifier.uint32Value,
                name: axis[kCTFontVariationAxisNameKey as String] as? String ?? "Axis \(identifier.uint32Value)",
                minimum: minimum.doubleValue,
                defaultValue: defaultValue.doubleValue,
                maximum: maximum.doubleValue
            )
        }
    }

    private static func readOS2Weight(from data: Data) throws -> Int {
        let bytes = [UInt8](data)

        func uint16(_ offset: Int) -> Int? {
            guard offset >= 0, offset + 2 <= bytes.count else {
                return nil
            }
            return (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
        }

        func uint32(_ offset: Int) -> Int? {
            guard offset >= 0, offset + 4 <= bytes.count else {
                return nil
            }

            return (Int(bytes[offset]) << 24) |
                (Int(bytes[offset + 1]) << 16) |
                (Int(bytes[offset + 2]) << 8) |
                Int(bytes[offset + 3])
        }

        guard let tableCount = uint16(4),
              tableCount <= (bytes.count - 12) / 16 else {
            throw FontKitError.invalidFontData
        }

        for index in 0..<tableCount {
            let record = 12 + index * 16

            guard record + 16 <= bytes.count else {
                throw FontKitError.invalidFontData
            }

            let tag = bytes[record..<(record + 4)]
            guard Array(tag) == Array("OS/2".utf8) else {
                continue
            }

            guard let offset = uint32(record + 8),
                  let length = uint32(record + 12),
                  length >= 6,
                  offset <= bytes.count,
                  length <= bytes.count - offset,
                  let weight = uint16(offset + 4) else {
                throw FontKitError.invalidFontData
            }

            return weight
        }

        throw FontKitError.invalidFontData
    }
}
