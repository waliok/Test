//
//  FavoritesManager.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

/// Central place to manage favorite movie IDs.
/// Now relies on the `UserDefault` wrapper (see `UserDefaults.favoriteMovieIDs`) instead of manual `UserDefaults` access.
final class FavoritesManager {
    static let shared = FavoritesManager()
    private init() {}

    /// Current favorite IDs (persisted).
    var ids: [Int] { UserDefaults.favoriteMovieIDs }

    /// Fast check whether an id is in favorites.
    func isFavorite(_ id: Int) -> Bool {
        return UserDefaults.favoriteMovieIDs.contains(id)
    }

    /// Toggle a movie id in favorites and persist.
    func toggle(_ id: Int) {
        update { set in
            if set.contains(id) { set.remove(id) } else { set.insert(id) }
        }
    }

    /// Remove a movie id from favorites and persist. No-op if not present.
    func remove(_ id: Int) {
        update { set in
            set.remove(id)
        }
    }

    /// Internal helper: mutate the Set form, then save back via the property wrapper
    /// and notify listeners about the change.
    private func update(_ transform: (inout Set<Int>) -> Void) {
        var set = Set(UserDefaults.favoriteMovieIDs)
        transform(&set)
        UserDefaults.favoriteMovieIDs = Array(set)
    }
}
