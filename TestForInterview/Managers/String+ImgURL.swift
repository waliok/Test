//
//  String+ImgURL.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

extension String {
    func toImgURL() -> URL? { URL(string: "https://image.tmdb.org/t/p/w500\(self)") }
}
