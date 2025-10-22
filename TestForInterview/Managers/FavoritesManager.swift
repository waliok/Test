//
//  FavoritesManager.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()
    private let key = "favorite_movie_ids"
    private var set: Set<Int> = []
    var ids: [Int] { Array(set) }

    private init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [Int] {
            set = Set(saved)
        }
    }
    func isFavorite(_ id: Int) -> Bool { set.contains(id) }
    func toggle(_ id: Int) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        UserDefaults.standard.set(Array(set), forKey: key)
        NotificationCenter.default.post(name: .favoritesChanged, object: nil)
    }
    func remove(_ id: Int) {
        if set.contains(id) { set.remove(id) }
        UserDefaults.standard.set(Array(set), forKey: key)
        NotificationCenter.default.post(name: .favoritesChanged, object: nil)
    }
}
extension Notification.Name { static let favoritesChanged = Notification.Name("favoritesChanged") }
