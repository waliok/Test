//
//  MovieRseponse.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

struct MovieListResponse: Codable {
  let page: Int
  let results: [Movie]
  let totalPages: Int?
  let totalResults: Int?
}
