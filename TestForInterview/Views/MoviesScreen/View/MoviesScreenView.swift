//
//  MoviesScreenView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

final class MoviesScreenView: UIView {
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let inset: CGFloat = 16.5
        let width = (UIScreen.main.bounds.width - inset * 2 - layout.minimumInteritemSpacing) / 2
        layout.itemSize = CGSize(width: width, height: width * 1.65)
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(cell: MovieCell.self)
        cv.register(footer: LoadingFooterView.self)
        return cv
    }()
    
    let refreshControl = UIRefreshControl()
    
    private let bottomSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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

extension MoviesScreenView {
    
    private func setup() {
        backgroundColor = .bg
        collectionView.refreshControl = refreshControl
    }
    
    private func setupLayout() {
        add(subviews: collectionView, bottomSpinner)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            bottomSpinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomSpinner.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Helpers used by the VC
    func reloadData() { collectionView.reloadData() }
    func reloadSection(_ number: Int) { collectionView.reloadSections(IndexSet(integer: number)) }
    func insertItems(at indexPaths: [IndexPath]) { collectionView.insertItems(at: indexPaths) }
    func numberOfItemsInSection(_ number: Int) -> Int { collectionView.numberOfItems(inSection: number) }
    func startBottomSpinner() { bottomSpinner.startAnimating() }
    func stopBottomSpinner() { bottomSpinner.stopAnimating() }
}
