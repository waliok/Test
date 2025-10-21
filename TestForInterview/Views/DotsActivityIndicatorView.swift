//
//  DotsActivityIndicatorView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

final class DotsActivityIndicatorView: UIView {
    private let replicator = CAReplicatorLayer()
    private let dot = CALayer()
    private var isAnimating = false

    /// Настройки под макет
    private let dotCount = 12
    private let radius: CGFloat = 28
    private let dotSize: CGFloat = 10
    private let duration: CFTimeInterval = 1.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(replicator)

        // точка
        dot.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
        dot.cornerRadius = dotSize / 2
        dot.backgroundColor = UIColor.label.withAlphaComponent(0.6).cgColor
        dot.shadowOpacity = 0.0 // можно чуть подсветить, если хочешь
        replicator.addSublayer(dot)

        // репликатор
        replicator.instanceCount = dotCount
        let angle = (2 * CGFloat.pi) / CGFloat(dotCount)
        replicator.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1)
        replicator.instanceDelay = duration / Double(dotCount)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        replicator.frame = bounds

        // располагем первую точку справа от центра и крутим вокруг
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        dot.position = CGPoint(x: center.x + radius, y: center.y)
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        // scale + opacity
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 0.3

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1.0
        opacity.toValue = 0.2

        let group = CAAnimationGroup()
        group.animations = [scale, opacity]
        group.duration = duration
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        dot.add(group, forKey: "pulse")
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        dot.removeAnimation(forKey: "pulse")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // автоадаптация под светлую/тёмную тему
        dot.backgroundColor = UIColor.label.withAlphaComponent(0.6).cgColor
    }
}
