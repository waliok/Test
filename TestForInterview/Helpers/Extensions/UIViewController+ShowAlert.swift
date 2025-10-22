//
//  UIViewController+ShowAlert.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

extension UIViewController {
    typealias Action = () -> Void

    func showBluetoothOffAlert(callback: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Bluetooth is off", message: "Please turn on your Bluetooth", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            callback?()
        })

        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { [weak self] _ in
            callback?()
            self?.navigateToAppSettings()
        }))

        present(alert, animated: true)
    }

    func openAppSettingsAlert(title: String, message: String, cancelAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            cancelAction?()
        }

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { [weak self] _ in
            self?.navigateToAppSettings()
        }

        alert.addAction(cancelAction)
        alert.addAction(settingsAction)

        present(alert, animated: true, completion: nil)
    }

    private func navigateToAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            Task {
                await UIApplication.shared.open(url)
            }
        }
    }

    func showAlert(title: String, message: String, actionTitle: String? = "OK", actionHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))

        present(alert, animated: true, completion: nil)
    }

    func showError(title: String? = "Error", message: String, actionTitle: String? = "OK", actionHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))

        present(alert, animated: true, completion: nil)
    }

    func showOkAlert(title: String?, message: String?) {
        assert((title ?? message) != nil, "Title OR message must be passed in")

        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(.gotIt)
        present(ac, animated: true)
    }

    func showDeleteConfirmation(title: String, message: String?, onConfirm: @escaping Action) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            onConfirm()
        }))

        ac.addAction(.cancel)
        present(ac, animated: true)
    }

    func showAlertWithActions(title: String?, message: String?, actions: [UIAlertAction]) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            ac.addAction(action)
        }

        present(ac, animated: true)
    }

    func showActionSheet(title: String?, message: String?, actions: [UIAlertAction]) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for action in actions {
            ac.addAction(action)
        }

        present(ac, animated: true)
    }
}

extension UIAlertAction {
    static var gotIt: UIAlertAction {
        UIAlertAction(title: "Got it", style: .default, handler: nil)
    }

    static var cancel: UIAlertAction {
        UIAlertAction(title: "Cancel", style: .default, handler: nil)
    }
}
