//
//  Font.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit
import SwiftUI

// MARK: - UIFont Extension
// Provides a unified way to use custom fonts in UIKit
extension UIFont {
    // Enum defining supported custom font styles for UIKit
    enum UIFontCustom {
        // Currently supports the Roboto font with configurable weight and size
        case roboto(weight: UIFont.Weight, size: CGFloat)

        // Returns a UIFont instance for the selected custom font
        var font: UIFont {
            switch self {
            case .roboto(let weight, let size):
                let name = fontName(for: weight)
                // Fallback to system font if custom font is not available
                return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
            }
        }

        // Maps UIFont.Weight to the corresponding Roboto font file name
        private func fontName(for weight: UIFont.Weight) -> String {
            switch weight {
            case .bold: return "Roboto-Bold"
            case .medium: return "Roboto-Medium"
            case .semibold: return "Roboto-SemiBold"
            case .light: return "Roboto-Light"
            case .thin: return "Roboto-Thin"
            default: return "Roboto-Regular"
            }
        }
    }

    // Helper method to easily get a custom UIFont
    static func custom(_ font: UIFontCustom) -> UIFont {
        font.font
    }
}

// MARK: - Font Extension
// Provides a unified way to use custom fonts in SwiftUI
extension Font {
    // Enum defining supported custom font styles for SwiftUI
    enum CustomFont {
        // Currently supports Roboto font with customizable weight and size
        case roboto(weight: Font.Weight, size: CGFloat)

        // Returns a SwiftUI Font instance for the selected custom font
        var font: Font {
            switch self {
            case .roboto(let weight, let size):
                Font.custom(fontName(for: weight), size: size)
            }
        }

        // Maps SwiftUI Font.Weight to the corresponding Roboto font file name
        private func fontName(for weight: Font.Weight) -> String {
            switch weight {
            case .bold: return "Roboto-Bold"
            case .medium: return "Roboto-Medium"
            case .semibold: return "Roboto-SemiBold"
            case .light: return "Roboto-Light"
            case .thin: return "Roboto-Thin"
            default: return "Roboto-Regular"
            }
        }
    }

    // Adds convenience method for using CustomFont in SwiftUI
    static func custom(_ font: CustomFont) -> Font {
        font.font
    }
}
