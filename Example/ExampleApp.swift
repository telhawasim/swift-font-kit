//
//  ExampleApp.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import SwiftUI
import SwiftFontKit

@main
struct ExampleApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    do {
                        try await SwiftFontKit.shared.preload([
                            .google("Inter", weight: .regular),
                            .google("Inter", weight: .bold),
                            .google("Poppins", weight: .medium),
                            .google("Roboto", weight: .medium, style: .italic)
                        ])
                    } catch {
                        print("Preloading failed:", error)
                    }
                }
        }
    }
}
