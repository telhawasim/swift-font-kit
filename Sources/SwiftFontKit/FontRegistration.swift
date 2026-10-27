//
//  FontRegistration.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation
import CoreText

struct FontRegistry {

    /// Helper model
    private struct WeightAxis {
        let identifier: UInt32
        let minimum: Double
        let maximum: Double
    }

    // MARK: - PROPERTIES -

    /// Private
    private var registeredFiles: Set<URL> = []

    mutating func register(fileURL: URL, request: FontRequest) throws -> FontHandle {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fileURL as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let postScriptName = CTFontDescriptorCopyAttribute(
                descriptor,
                kCTFontNameAttribute
              ) as? String,
              let familyName = CTFontDescriptorCopyAttribute(
                descriptor,
                kCTFontFamilyNameAttribute
              ) as? String
                else {
            throw FontKitError.invalidFontData
        }

        let ctFont = CTFontCreateWithFontDescriptor(descriptor, 14, nil)
        let weightAxis = Self.weightAxis(for: ctFont)

        if let weightAxis {
            let requestedWeight = Double(request.weight.rawValue)

            guard requestedWeight >= weightAxis.minimum,
                  requestedWeight <= weightAxis.maximum else {
                throw FontKitError.variantUnavailable(
                    "Weight \(request.weight.rawValue) is outside \(weightAxis.minimum)...\(weightAxis.maximum)"
                )
            }
        }

        if !registeredFiles.contains(fileURL) {
            var registrationError: Unmanaged<CFError>?

            let success = CTFontManagerRegisterFontsForURL(
                fileURL as CFURL,
                .process,
                &registrationError
            )

            guard success else {
                let descriptor = registrationError
                    .map { String(describing: $0.takeRetainedValue()) } ?? "Unknown Core Text error"

                throw FontKitError.registrationFailed(descriptor)
            }

            registeredFiles.insert(fileURL)
        }

        return FontHandle(
            postScriptName: postScriptName,
            familyName: familyName,
            weight: request.weight,
            style: request.style,
            weightAxisIdentifier: weightAxis?.identifier
        )
    }

    private static func weightAxis(for font: CTFont) -> WeightAxis? {
        guard let axes = CTFontCopyVariationAxes(font) as? [[String: Any]] else {
            return nil
        }

        /// OpenType tag: "wght"
        let weightTag: UInt32 = 0x77676874

        for axis in axes {
            guard let identifier = axis[kCTFontVariationAxisIdentifierKey as String] as? NSNumber,
                  identifier.uint32Value == weightTag,
                  let minimum = axis[kCTFontVariationAxisMinimumValueKey as String] as? NSNumber,
                  let maximum = axis[kCTFontVariationAxisMaximumValueKey as String] as? NSNumber
                    else {
                continue
            }

            return WeightAxis(
                identifier: identifier.uint32Value,
                minimum: minimum.doubleValue,
                maximum: maximum.doubleValue
            )
        }

        return nil
    }
}
