//
//  CustomUICollectionViewCell.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

class CustomUICollectionViewCell: UICollectionViewCell {
    var containerView = UIStackView()
    var enableHighlight = true
    var scaleValueOnTapEffect: CGAffineTransform = .init(scaleX: 0.95, y: 0.95)
    var highlightedBackgroundColor: UIColor? = .searchBack
    private var originalBackgroundColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        backgroundColor = .clear
    }

    func setupLayout() {}

    // Override touchesBegan to highlight background and apply scale effect with animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard enableHighlight else { return }
        layer.cornerRadius = 12
        originalBackgroundColor = containerView.backgroundColor
        let scaleTransform = scaleValueOnTapEffect
        // Scale down animation when touch begins
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut]
        ) { [weak self] in

            // Apply scaling and background color change
            self?.containerView.backgroundColor = self?.highlightedBackgroundColor
            self?.containerView.transform = scaleTransform
        }
    }

    // Override touchesEnded to reset background color and scale effect with animation
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard enableHighlight else { return }
        // Scale back to original size and background color when touch ends
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut]
        ) { [weak self] in

            self?.containerView.backgroundColor = self?.originalBackgroundColor
            self?.containerView.transform = .identity
        }
    }

    // Override touchesCancelled to reset background color and scale effect with animation
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard enableHighlight else { return }
        // Scale back to original size and background color if touch is cancelled
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut]
        ) { [weak self] in

            self?.containerView.backgroundColor = self?.originalBackgroundColor
            self?.containerView.transform = .identity
        }
    }
}
