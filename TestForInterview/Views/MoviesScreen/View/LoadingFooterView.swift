//
//  LoadingFooterView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

final class LoadingFooterView: UICollectionReusableView {
    static let kind = UICollectionView.elementKindSectionFooter
    static let id = "LoadingFooterView"

    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func start() { spinner.startAnimating() }
    func stop()  { spinner.stopAnimating() }
}
