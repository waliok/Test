//
//  UserDefaults.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    var storage: UserDefaults = .shared

    var wrappedValue: T {
        get { (storage.object(forKey: key) as? T) ?? defaultValue }
        set { storage.set(newValue, forKey: key) }
    }
}

extension UserDefaults {
    private static let themeKey = "app_theme"
    public static let shared = UserDefaults.standard

    // Persist AppTheme via its raw Int value
    @UserDefault(key: themeKey, defaultValue: AppTheme.system.rawValue)
    static var userInterfaceStyleRawValue: Int
}
