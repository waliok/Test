//
//  ThemeManager.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

enum AppTheme: Int { case system = 0, light, dark }

final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    /// The currently selected app theme persisted in UserDefaults
    var current: AppTheme {
        get { AppTheme(rawValue: UserDefaults.userInterfaceStyleRawValue) ?? .system }
        set {
            UserDefaults.userInterfaceStyleRawValue = newValue.rawValue
            apply(newValue)
        }
    }

    /// Call this once on app launch (e.g., in AppDelegate didFinishLaunching)
    func setup() {
        apply(current)
    }

    /// Apply theme to all windows across connected scenes
    func apply(_ theme: AppTheme) {
        let style: UIUserInterfaceStyle
        switch theme {
        case .system: style = .unspecified
        case .light:  style = .light
        case .dark:   style = .dark
        }
        applyStyleToAllWindows(style)
    }

    private func applyStyleToAllWindows(_ style: UIUserInterfaceStyle) {
        // Iterate over all connected scenes and their windows (iOS 13+)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }

    /// Toggle theme between light and dark and persist the change
    func toggleTheme() {
        switch current {
        case .light:
            current = .dark
        case .dark:
            current = .light
        case .system:
            // If current is system, default to dark
            current = .dark
        }
    }
}
