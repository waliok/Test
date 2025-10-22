//
//  MoviePage.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

struct MovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
    }
    
    var formattedReleaseDate: String {
        guard let releaseDate = releaseDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: releaseDate) else {
            return releaseDate
        }
        
        formatter.dateFormat = "d MMMM yyyy"
        let formatted = formatter.string(from: date).lowercased() // делаем месяц в нижнем регистре
        return formatted
    }
    
    var ratingText: String {
        guard let voteAverage = voteAverage else { return "N/A" }
        return String(format: "%.0f", voteAverage)
    }
}
