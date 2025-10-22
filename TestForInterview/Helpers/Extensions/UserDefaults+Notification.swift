//
//  UserDefaults.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

@propertyWrapper
struct UserDefault<T: Equatable> {
    let key: String
    let defaultValue: T
    var notificationName: Notification.Name?
    var storage: UserDefaults = .shared

    var wrappedValue: T {
        get {
            guard let value = storage.object(forKey: key) as? T else {
                return defaultValue
            }

            if let optional = value as? AnyOptional, optional.isNil {
                return defaultValue
            }

            return value
        }
        set {
            let oldValue = storage.object(forKey: key) as? T

            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }

            if let notificationName, oldValue != newValue {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
            }
        }
    }
}

extension UserDefaults {
    private static let themeKey = "app_theme"
    private static let favoritesKey = "favorite_movie_ids"
    public static let shared = UserDefaults.standard

    // Persist AppTheme via its raw Int value
    @UserDefault(key: themeKey, defaultValue: AppTheme.system.rawValue)
    static var userInterfaceStyleRawValue: Int
    
    // Persist favorite movie IDs as an array of Ints
    @UserDefault(key: favoritesKey, defaultValue: [], notificationName: .favoritesChanged)
    static var favoriteMovieIDs: [Int]
}


extension NSNotification.Name {
    static let favoritesChanged = NSNotification.Name(rawValue: "favoritesChanged")
}
