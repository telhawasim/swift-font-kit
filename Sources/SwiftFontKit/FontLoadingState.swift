//
//  FontLoadingState.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 30/10/2026.
//

import Foundation

/// Enum responsible for all font loading failure
public enum FontLoadingFailure: Error, LocalizedError, Sendable {
    case fontKit(FontKitError)
    case other(String)

    // MARK: - PROPERTIES -

    /// Computed
    public var errorDescription: String? {
        switch self {
        case .fontKit(let error):
            return error.localizedDescription

        case .other(let message):
            return message
        }
    }

    // MARK: - INITIALIZER -
    init(_ error: Error) {
        if let error = error as? FontKitError {
            self = .fontKit(error)
        } else {
            self = .other(error.localizedDescription)
        }
    }
}

/// Enum responsible for all font loading state
public enum FontLoadingState: Sendable {
    case idle
    case loading
    case loaded(FontHandle)
    case failed(FontLoadingFailure)

    // MARK: - PROPERTIES -

    /// Computed
    public var handle: FontHandle? {
        guard case .loaded(let handle) = self else {
            return nil
        }
        return handle
    }
}
