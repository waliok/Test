//
//  AsyncWebImageView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import SwiftUI
import SDWebImage

struct AsyncWebImageView: UIViewRepresentable {
    /// Remote image URL to display. When nil, a placeholder is shown.
    let url: URL?

    /// Reusable SF Symbol placeholder (built once).
    private static let placeholderSymbol: UIImage? = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        return UIImage(systemName: "photo.fill.on.rectangle.fill", withConfiguration: cfg)
    }()

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        // Static view configuration lives here to avoid repeating it in updates.
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .tertiarySystemFill
        iv.tintColor = .secondaryLabel
        iv.sd_imageTransition = .fade
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Configure the loading indicator based on current theme on every update.
        uiView.sd_imageIndicator = indicatorForCurrentTheme()
        uiView.sd_imageIndicator?.startAnimatingIndicator()

        // If no URL – show placeholder immediately and stop the indicator.
        guard let url = url else {
            uiView.image = Self.placeholderSymbol
            uiView.contentMode = .scaleAspectFit
            uiView.backgroundColor = .tertiarySystemFill
            uiView.sd_imageIndicator?.stopAnimatingIndicator()
            return
        }

        // Optimistic placeholder while the image is fetched.
        uiView.image = Self.placeholderSymbol

        uiView.sd_setImage(
            with: url,
            placeholderImage: nil,
            options: [.retryFailed, .scaleDownLargeImages, .continueInBackground]
        ) { image, error, _, _ in
            // Always stop the spinner when the request completes.
            defer { uiView.sd_imageIndicator?.stopAnimatingIndicator() }

            if image != nil && error == nil {
                // Success – fill the card.
                uiView.contentMode = .scaleAspectFill
                uiView.backgroundColor = .clear
            } else {
                // Failure – keep a pleasant placeholder look.
                uiView.image = Self.placeholderSymbol
                uiView.contentMode = .scaleAspectFit
                uiView.backgroundColor = .tertiarySystemFill
            }
        }
    }

    // MARK: - Helpers
    private func indicatorForCurrentTheme() -> SDWebImageIndicator {
        if ThemeManager.shared.current == .dark {
            return SDWebImageActivityIndicator.whiteLarge
        } else {
            return SDWebImageActivityIndicator.grayLarge
        }
    }
}
