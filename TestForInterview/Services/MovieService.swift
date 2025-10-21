//
//  MovieService.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

struct MovieService {
  func fetchTopRated(page: Int = 1, completion: @escaping (Result<MovieListResponse, Error>) -> Void) {
    NetworkManager.shared.request(path: "/movie/top_rated", params: ["page":"\(page)"], completion: completion)
  }

  func searchMovies(query: String, page: Int = 1, completion: @escaping (Result<MovieListResponse, Error>) -> Void) {
    NetworkManager.shared.request(path: "/search/movie", params: ["query": query, "page":"\(page)"], completion: completion)
  }

  func fetchMovieDetails(id: Int, completion: @escaping (Result<MovieDetails, Error>) -> Void) {
    NetworkManager.shared.request(path: "/movie/\(id)", params: [:], completion: completion)
  }
}
