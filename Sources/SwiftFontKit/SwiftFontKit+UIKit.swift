//
//  SwiftFontKit+UIKit.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import Foundation
import UIKit
import CoreText

public extension FontWeight {

    var uiKitWeight: UIFont.Weight {
        switch self {
        case .thin: .thin
        case .extraLight: .ultraLight
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .extraBold: .heavy
        case .black: .black
        }
    }
}

public extension FontHandle {

    @MainActor
    func uiFont(
        size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle = .body,
        compatibleWith traits: UITraitCollection? = nil
    ) -> UIFont {
        let baseFont: UIFont

        if let axisIdentifier = weightAxisIdentifier {
            let variationKey = UIFontDescriptor.AttributeName(
                rawValue: kCTFontVariationAttribute as String
            )

            let descriptor = UIFontDescriptor(name: postScriptName, size: size).addingAttributes([
                variationKey: [
                    NSNumber(value: axisIdentifier): NSNumber(value: weight.rawValue)
                ]
            ])

            baseFont = UIFont(descriptor: descriptor, size: size)
        } else {
            baseFont = UIFont(name: postScriptName, size: size) ?? UIFont
                .systemFont(ofSize: size, weight: weight.uiKitWeight)
        }

        return UIFontMetrics(forTextStyle: textStyle)
            .scaledFont(for: baseFont, compatibleWith: traits)
    }
}
