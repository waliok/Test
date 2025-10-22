//
//  UITextField+OnTouchUpOutside.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

extension UITextField {
    /// Adds a tap gesture to the provided view to dismiss the keyboard when tapping outside this text view.
    func addDismissOnTouchUpOutside(in containerView: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(_las_dismissKeyboardOnTapOutside))
        tapGesture.cancelsTouchesInView = false
        containerView.addGestureRecognizer(tapGesture)
    }

    @objc private func _las_dismissKeyboardOnTapOutside() {
        resignFirstResponder()
    }
}
