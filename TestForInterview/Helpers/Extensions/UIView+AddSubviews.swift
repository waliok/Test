//
//  UIView+AddSubviews.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

extension UIView {
    func add(subviews: UIView...) {
        subviews.forEach(addSubview)
    }
}
