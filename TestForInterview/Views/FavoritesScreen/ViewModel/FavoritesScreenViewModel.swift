//
//  FavoritesScreenViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import Foundation

final class FavoritesScreenViewModel {
    private let service = MovieService()
    private(set) var movies: [Movie] = []
    private var suppressNextNotification = false
    
    var onLoading: ((Bool) -> Void)?
    var onReload: (() -> Void)?
    var onItemsDeleted: ((_ indexes: [Int]) -> Void)?
    var onError: ((Error) -> Void)?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onFavoritesChanged), name: .favoritesChanged, object: nil)
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    
    @objc private func onFavoritesChanged() {
        // Ignore self-originated updates
        if suppressNextNotification { suppressNextNotification = false; return }
        load()
    }
    
    func load() {
        let ids = Array(FavoritesManager.shared.ids)
        onLoading?(true)
        movies.removeAll()
        
        guard !ids.isEmpty else {
            onLoading?(false)
            onReload?() // will show empty state
            return
        }
        
        let group = DispatchGroup()
        var loaded: [Movie] = []
        var seen = Set<Int>()
        var firstError: Error?
        
        ids.forEach { id in
            group.enter()
            service.fetchMovieDetails(id: id) { result in
                switch result {
                case .success(let details):
                    let m = Movie(id: details.id, title: details.title, overview: details.overview, posterPath: details.posterPath, releaseDate: details.releaseDate, voteAverage: details.voteAverage)
                    if !seen.contains(m.id) { loaded.append(m); seen.insert(m.id) }
                case .failure(let err):
                    if firstError == nil { firstError = err }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.movies = loaded.sorted { $0.title < $1.title }
            self.onLoading?(false)
            self.onReload?()
            if let err = firstError { self.onError?(err) }
        }
    }
    
    func removeFavorite(id: Int) {
        // local mutation + UI indexes
        if let idx = movies.firstIndex(where: { $0.id == id }) {
            movies.remove(at: idx)
            onItemsDeleted?([idx])
        }
        // Persist and suppress the coming notification from FavoritesManager
        suppressNextNotification = true
        FavoritesManager.shared.remove(id)
    }
}
