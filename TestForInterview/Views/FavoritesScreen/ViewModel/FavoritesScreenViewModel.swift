//
//  FavoritesScreenViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import Foundation
import Combine

final class FavoritesScreenViewModel {
    private let service = MovieService()
    private(set) var movies: [Movie] = []
    private var suppressNextNotification = false
    
    var onLoading: ((Bool) -> Void)?
    var onReload: (() -> Void)?
    var onItemsDeleted: ((_ indexes: [Int]) -> Void)?
    var onError: ((Error) -> Void)?
    let alertSubject = PassthroughSubject<AlertType, Never>()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onFavoritesChanged), name: .favoritesChanged, object: nil)
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    
    @objc private func onFavoritesChanged() {
        if suppressNextNotification { suppressNextNotification = false; return }
        load()
    }
    
    func load() {
        let ids = FavoritesManager.shared.ids
        onLoading?(true)

        guard NetworkMonitor.shared.isConnected else {
            print("No Internet Connection")
            onLoading?(false)
            alertSubject.send(.noInternet)
            return
        }

        movies.removeAll()

        guard !ids.isEmpty else {
            onLoading?(false)
            onReload?()
            return
        }

        let group = DispatchGroup()
        // Keep deterministic order matching `ids`
        var byId: [Int: Movie] = [:]
        let syncQ = DispatchQueue(label: "FavoritesVM.load.sync")
        var firstError: Error?

        ids.forEach { [weak self] id in
            group.enter()
            self?.service.fetchMovieDetails(id: id) { result in
                switch result {
                case .success(let details):
                    let m = Movie(
                        id: details.id,
                        title: details.title,
                        overview: details.overview,
                        posterPath: details.posterPath,
                        releaseDate: details.releaseDate,
                        voteAverage: details.voteAverage
                    )
                    syncQ.async { byId[m.id] = m; group.leave() }
                case .failure(let err):
                    syncQ.async {
                        if firstError == nil { firstError = err }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // Build movies in the exact order of `ids`
            self.movies = ids.compactMap { byId[$0] }
            self.onLoading?(false)
            self.onReload?()
            if let err = firstError {
                self.onError?(err)
                self.alertSubject.send(.error(err.localizedDescription))
            }
        }
    }
    
    func removeFavorite(id: Int) {
        if let idx = movies.firstIndex(where: { $0.id == id }) {
            movies.remove(at: idx)
            onItemsDeleted?([idx])
        }
        suppressNextNotification = true
        FavoritesManager.shared.remove(id)
    }
}
