//
//  AsyncWebImageView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import SwiftUI
import SDWebImage

struct WebImageView: UIViewRepresentable {
  let url: URL?

  func makeUIView(context: Context) -> UIImageView {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFill
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.clipsToBounds = true
    return iv
  }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        let indicator = ThemeManager.shared.current == .dark ? SDWebImageActivityIndicator.whiteLarge : SDWebImageActivityIndicator.grayLarge
        uiView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed], completed: nil)
        uiView.sd_imageIndicator = indicator
        uiView.sd_imageIndicator?.startAnimatingIndicator()
    }
}
