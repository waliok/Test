//
//
//  DetailsViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation
import Combine
import Network

final class DetailsScreenViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var isFavorite: Bool = false
    
    let alertSubject = PassthroughSubject<AlertType, Never>()
    
    private let service = MovieService()
    private var movieId: Int
    
    init(movieId: Int) {
        self.movieId = movieId
        self.isFavorite = FavoritesManager.shared.isFavorite(movieId)
        fetch()
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged), name: .favoritesChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func favoritesChanged() {
        DispatchQueue.main.async {
            self.isFavorite = FavoritesManager.shared.isFavorite(self.movieId)
        }
    }
    
    func fetch() {
        guard NetworkMonitor.shared.isConnected else {
            print("No Internet Connection")
            alertSubject.send(.noInternet)
            return
        }
        service.fetchMovieDetails(id: movieId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let d):
                    self?.details = d
                case .failure(let err):
                    print("Details error: \(type(of: err)) - \(err.localizedDescription)")
                    self?.alertSubject.send(.error(err.localizedDescription))
                }
            }
        }
    }
    
    func toggleFavorite() {
        guard let d = details else { return }
        let movie = Movie(id: d.id, title: d.title, overview: d.overview, posterPath: d.posterPath, releaseDate: d.releaseDate, voteAverage: d.voteAverage)
        FavoritesManager.shared.toggle(movie.id)
        isFavorite = FavoritesManager.shared.isFavorite(movie.id)
    }
}
