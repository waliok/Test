//
//  FirstLoadOverlay.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

final class FirstLoadOverlay: UIView {
    private let spinner = DotsActivityIndicatorView()
    private let dim = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true // блокируем тапки под низом

        addSubview(dim)
        addSubview(spinner)

        dim.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: topAnchor),
            dim.leadingAnchor.constraint(equalTo: leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: 120),
            spinner.heightAnchor.constraint(equalToConstant: 120),
        ])

        // лёгкое затемнение фона, чтобы смотрелось как в макете
        dim.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)

        // круглая «невидимая» площадка, чтобы было проще позиционировать
        spinner.layer.cornerRadius = 60
        spinner.backgroundColor = .clear

        alpha = 0 // появляемся анимацией
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(on view: UIView) {
        guard superview == nil else { return }
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        layoutIfNeeded()
        spinner.startAnimating()

        // анимация появления
        self.alpha = 0
        self.spinner.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 1
            self.spinner.transform = .identity
        }
    }

    func hideAndRemove() {
        spinner.stopAnimating()
        // анимация исчезновения
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn], animations: {
            self.alpha = 0
            self.spinner.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
