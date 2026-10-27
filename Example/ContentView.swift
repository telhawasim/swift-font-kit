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
