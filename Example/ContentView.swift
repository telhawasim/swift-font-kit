//
//  ContentView.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import SwiftUI
import SwiftFontKit

struct ContentView: View {

    // MARK: - LIFECYCLE -
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome Back")
                .googleFont("Inter", size: 32, weight: .bold, relativeTo: .largeTitle)

            Text("Build something amazing today.")
                .googleFont("Poppins", size: 18, weight: .regular)

            Text("Your journey starts here.")
                .googleFont("Roboto", size: 15, weight: .medium, style: .italic)
        }
        .padding()
    }
}

struct ContentViewLocalFont: View {

    // MARK: - PROPERTIES -

    let fileURL = URL(string: "")! /// Placeholder url for local font

    /// Font included in the app target
    let request = try FontRequest.bundled("Brand-Regular.ttf", in: .main)
    let handle = try await SwiftFontKit.shared.load(request)

    /// Font included in another Swift package target
    let packageRequest = try FontRequest.bundled("Brand-Bold.otf", in: .module, weight: .bold)

    /// Font in the app's Documents directory
    let localRequest = FontRequest.local(fileURL)
    let localHandle = try await SwiftFontKit.shared.load(localRequest)

    var body: some View {
        Text("Offline typography")
            .localFont(fileURL, size: 24, weight: .bold)
    }
}
