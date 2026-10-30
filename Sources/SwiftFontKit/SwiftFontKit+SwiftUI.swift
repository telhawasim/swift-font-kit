//
//  SwiftFontKit+SwiftUI.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import SwiftUI
import UIKit

private extension FontWeight {
    var swiftUIWeight: Font.Weight {
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

private extension Font.TextStyle {
    var uiKitStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}

private extension DynamicTypeSize {
    var uiKitCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge

        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge

        @unknown default: .large
        }
    }
}

@MainActor
private struct GoogleFontModifier: ViewModifier {

    // MARK: - PROPERTIES -

    /// Normal
    let request: FontRequest
    let size: CGFloat
    let relativeTo: Font.TextStyle
    /// State
    @State private var handle: FontHandle?
    /// Environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Computed
    private var resolvedFont: Font {
        let traits = UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.uiKitCategory)

        if let handle {
            return Font(
                handle.uiFont(size: size, relativeTo: relativeTo.uiKitStyle, compatibleWith: traits)
            )
        }

        let fallback = UIFont.systemFont(ofSize: size, weight: request.weight.uiKitWeight)
        let scaledFallback = UIFontMetrics(forTextStyle: relativeTo.uiKitStyle).scaledFont(
            for: fallback,
            compatibleWith: traits
        )

        return Font(scaledFallback)
    }

    // MARK: - LIFECYCLE -
    func body(content: Content) -> some View {
        content
            .font(resolvedFont)
            .task(id: request) {
                handle = nil

                do {
                    let loaded = try await SwiftFontKit.shared.load(request)

                    guard !Task.isCancelled else { return }

                    handle = loaded
                } catch {
                    /// Keep the Dynamic Type-aware system fallback.
                    handle = nil
                }
            }
    }
}

public extension View {

    func googleFont(
        _ family: String,
        size: CGFloat,
        weight: FontWeight = .regular,
        style: FontStyle = .normal,
        relativeTo: Font.TextStyle = .body
    ) -> some View {
        modifier(GoogleFontModifier(
            request: .google(family, weight: weight, style: style),
            size: size,
            relativeTo: relativeTo
        ))
    }

    func remoteFont(
        _ url: URL,
        size: CGFloat,
        weight: FontWeight = .regular,
        style: FontStyle = .normal,
        relativeTo: Font.TextStyle = .body
    ) -> some View {
        modifier(GoogleFontModifier(
            request: .remote(url, weight: weight, style: style),
            size: size,
            relativeTo: relativeTo
        ))
    }

    func localFont(
        _ fileURL: URL,
        size: CGFloat,
        weight: FontWeight = .regular,
        style: FontStyle = .normal,
        relativeTo: Font.TextStyle = .body
    ) -> some View {
        modifier(GoogleFontModifier(
            request: .local(fileURL, weight: weight, style: style),
            size: size,
            relativeTo: relativeTo
        ))
    }
}
