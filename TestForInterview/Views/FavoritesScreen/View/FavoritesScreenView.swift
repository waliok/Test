//
//  FavoritesScreenView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

final class FavoritesScreenView: UIView {
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let inset: CGFloat = 16.5
        let w = (UIScreen.main.bounds.width - inset*2 - layout.minimumInteritemSpacing) / 2
        layout.itemSize = CGSize(width: w, height: w * 1.65)
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(cell: MovieCell.self)
        return cv
    }()

    let refreshControl = UIRefreshControl()

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emptyStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iv = UIImageView(image: UIImage(resource: .emptyListPlaceholderIcon))
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .vertical)
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "No favorites yet"
        label.font = .custom(.roboto(weight: .semibold, size: 16))
        label.textColor = .secondaryLabel
        stack.addArrangedSubview(iv)
        stack.addArrangedSubview(label)
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 120),
            iv.heightAnchor.constraint(equalToConstant: 120)
        ])
        stack.isHidden = true
        return stack
    }()

    var collectionViewDataSource: UICollectionViewDataSource? {
        get { collectionView.dataSource }
        set { collectionView.dataSource = newValue }
    }
    var collectionViewDelegate: UICollectionViewDelegate? {
        get { collectionView.delegate }
        set { collectionView.delegate = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Other methods

extension FavoritesScreenView {
    private func setup() {
        backgroundColor = .bg
        collectionView.refreshControl = refreshControl
    }

    private func setupLayout() {
        add(subviews: collectionView, spinner, emptyStack)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            emptyStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Helpers used by the VC
    func reloadData() { collectionView.reloadData() }
    func numberOfItemsInSection(_ number: Int) -> Int { collectionView.numberOfItems(inSection: number) }
    func setLoading(_ loading: Bool) { loading ? spinner.startAnimating() : spinner.stopAnimating() }
    func showEmpty(_ show: Bool) { emptyStack.isHidden = !show; collectionView.isHidden = show }
}
