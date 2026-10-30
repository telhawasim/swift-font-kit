//
//  FontLoader.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 30/10/2026.
//

import Foundation
import Combine

@MainActor
public final class FontLoader: ObservableObject {

    // MARK: - PROPERTIES -

    /// Published
    @Published public private(set) var state: FontLoadingState = .idle
    /// Public
    public let request: FontRequest
    /// Private
    private let kit: SwiftFontKit
    private var generation = 0

    // MARK: - INITIALIZER -
    public init(request: FontRequest, kit: SwiftFontKit = .shared) {
        self.request = request
        self.kit = kit
    }

    public func load() async {
        generation += 1
        let currentGeneration = generation
        state = .loading

        do {
            let handle = try await kit.load(request)

            guard currentGeneration == generation else {
                return
            }

            if Task.isCancelled {
                state = .idle
            } else {
                state = .loaded(handle)
            }
        } catch {
            guard currentGeneration == generation else {
                return
            }

            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                state = .failed(FontLoadingFailure(error))
            }
        }
    }
}
