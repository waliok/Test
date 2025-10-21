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
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var formattedReleaseDate: String {
        guard let releaseDate = releaseDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: releaseDate) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return releaseDate
    }
    
    var ratingText: String {
        guard let voteAverage = voteAverage else { return "N/A" }
        return String(format: "%.1f", voteAverage)
    }
}
