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
        uiView.clipsToBounds = true
        uiView.backgroundColor = UIColor.tertiarySystemFill
        uiView.tintColor = UIColor.secondaryLabel
        uiView.contentMode = .scaleAspectFit
        
        // Настраиваем индикатор загрузки в зависимости от темы
        let indicator = ThemeManager.shared.current == .dark
        ? SDWebImageActivityIndicator.whiteLarge
        : SDWebImageActivityIndicator.grayLarge
        
        uiView.sd_imageIndicator = indicator
        uiView.sd_imageIndicator?.startAnimatingIndicator()
        uiView.sd_imageTransition = .fade
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        let placeholderIMG = UIImage(systemName: "photo.fill.on.rectangle.fill", withConfiguration: symbolConfig)
        uiView.image = placeholderIMG
        
        uiView.sd_setImage(
            with: url,
            placeholderImage: nil,
            options: [.retryFailed, .scaleDownLargeImages, .continueInBackground]
        ) { image, error, _, _ in
            // Останавливаем индикатор в любом случае
            uiView.sd_imageIndicator?.stopAnimatingIndicator()
            
            if let _ = image, error == nil {
                // Реальное изображение — заполняем карточку
                uiView.contentMode = .scaleAspectFill
                uiView.backgroundColor = .clear
            } else {
                // Ошибка — оставляем плейсхолдер в стиле "карточки"
                uiView.contentMode = .scaleAspectFit
                uiView.image = placeholderIMG
                uiView.backgroundColor = UIColor.tertiarySystemFill
            }
        }
    }
}
