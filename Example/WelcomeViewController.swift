//
//  WelcomeViewController.swift
//  SwiftFontKit
//
//  Created by Telha Wasim on 26/10/2026.
//

import UIKit
import SwiftFontKit

final class WelcomeViewController: UIViewController {

    // MARK: - PROPERTIES -

    /// Private
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleLabel)

        titleLabel.text = "Welcome"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true

        Task { [weak self] in
            do {
                let handle = try await SwiftFontKit.shared.load(.google("Inter", weight: .bold))

                guard let self else { return }

                titleLabel.font = handle.uiFont(size: 32, relativeTo: .largeTitle)
            } catch {
                print("Font loading failed", error)
            }
        }
    }
}
