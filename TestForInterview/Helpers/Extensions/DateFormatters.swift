//
//  DateFormatters.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import Foundation

extension DateFormatter {
    static let movieInputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let movieDetailsOutputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}
