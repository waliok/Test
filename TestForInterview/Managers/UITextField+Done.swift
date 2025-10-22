//
//  UITextField+Done.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

extension UITextField {
    /// Adds a "Done" button above the keyboard to dismiss it.
    func addDoneButtonOnKeyboard() {
        let doneToolbar = UIToolbar()
        doneToolbar.sizeToFit()
        doneToolbar.barStyle = .default
        doneToolbar.tintColor = .bg

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        doneButton.tintColor = .txt
        let items = [flexibleSpace, doneButton]
        doneToolbar.items = items

        inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        resignFirstResponder()
    }
}

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
