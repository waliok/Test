//
//  SearchScreenView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit
import Combine

final class SearchScreenView: UIView {
    
    private(set) lazy var searchField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Search"
        tf.clearButtonMode = .whileEditing
        tf.backgroundColor = .searchBack
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.leftViewMode = .always
        tf.font = .custom(.roboto(weight: .bold, size: 18))
        let iv = UIImageView()
        // Try SwiftGen-like resource first, fall back to named
        let img = UIImage(resource: .searchIcon)
        iv.image = img
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 55, height: 34))
        iv.frame = CGRect(x: 20, y: 7, width: 20, height: 20)
        container.addSubview(iv)
        tf.leftView = container
        tf.returnKeyType = .search
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.addDoneButtonOnKeyboard()
        tf.addDismissOnTouchUpOutside(in: self)
        return tf
    }()
    
    var searchFieldDelegate: UITextFieldDelegate? {
        get { searchField.delegate }
        set { searchField.delegate = newValue }
    }

    private let resultsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .txt
        l.font = .custom(.roboto(weight: .medium, size: 18))
        l.text = "Search results (0)"
        l.isHidden = true // hidden until first search
        return l
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let inset: CGFloat = 16.5
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let width = (UIScreen.main.bounds.width - inset * 2 - layout.minimumInteritemSpacing) / 2
        layout.itemSize = CGSize(width: width, height: width * 1.65)
        layout.sectionInset =  UIEdgeInsets(top: 16.5, left: 16.5, bottom: 16.5, right: 16.5)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.register(cell: MovieCell.self)
        return cv
    }()
    
    var collectionViewDataSource: UICollectionViewDataSource? {
        get { collectionView.dataSource }
        set { collectionView.dataSource = newValue }
    }
    
    var collectionViewDelegate: UICollectionViewDelegate? {
        get { collectionView.delegate }
        set { collectionView.delegate = newValue }
    }
    
    var collectionBottomConstraint: NSLayoutConstraint?

    private let emptyPlaceholder: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(resource: .emptyListPlaceholderIcon)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .tertiaryLabel
        iv.isHidden = true // hidden before search
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .bg
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Other methods

extension SearchScreenView {
    
    private func setupLayout() {
        add(subviews: searchField, resultsLabel, collectionView, emptyPlaceholder)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            searchField.heightAnchor.constraint(equalToConstant: 50),

            resultsLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            resultsLabel.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),
            resultsLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: resultsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        collectionBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        collectionBottomConstraint!.isActive = true

        NSLayoutConstraint.activate([
            emptyPlaceholder.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            emptyPlaceholder.widthAnchor.constraint(equalToConstant: 140),
            emptyPlaceholder.heightAnchor.constraint(equalTo: emptyPlaceholder.widthAnchor)
        ])
    }
    
    func hideEmptyPlaceholder(_ hide: Bool) {
        emptyPlaceholder.isHidden = hide
    }
    
    func reloadCollectionView() {
        collectionView.reloadData()
    }
    
    func setResultsCount(_ count: Int) {
        resultsLabel.text = "Search results (\(count))"
    }
    
    func hideResultsLabel(_ hide: Bool) {
        resultsLabel.isHidden = hide
    }
}
