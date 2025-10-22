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
