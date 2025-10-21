//
//  Movie.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//


import Foundation

struct Movie: Codable {
  let id: Int
  let title: String
  let overview: String?
  let posterPath: String?
  let releaseDate: String?
  let voteAverage: Double?
}
