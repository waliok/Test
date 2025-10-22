//
//  SearchScreenViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit


//
//  SearchScreenViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

// MARK: - SearchView (all UI lives here)
final class SearchView: UIView {
    // Public subviews we need to access from VC
    lazy var searchField: UITextField = {
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

    let resultsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .txt
        l.font = .custom(.roboto(weight: .medium, size: 18))
        l.text = "Search results (0)"
        l.isHidden = true // hidden until first search
        return l
    }()

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    var collectionBottomConstraint: NSLayoutConstraint?

    let emptyPlaceholder: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(resource: .emptyListPlaceholderIcon) as UIImage? {
            iv.image = img
        } else {
            iv.image = UIImage(named: "emptyListPlaceholderIcon")
        }
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .tertiaryLabel
        iv.isHidden = true // hidden before search
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .bg
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        addSubview(searchField)
        addSubview(resultsLabel)
        addSubview(collectionView)
        addSubview(emptyPlaceholder)

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
}

// MARK: - SearchViewController
final class SearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {

    private let service = MovieService()
    private var movies: [Movie] = []
    private var debounceTimer: Timer?

    // Strongly-typed access to our view
    private var searchView = SearchView()
    private var collectionBottomConstraint: NSLayoutConstraint?

    // Use custom view
    override func loadView() {
        super.loadView()
        view = searchView
        collectionBottomConstraint = searchView.collectionBottomConstraint
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        setupNavbar()

        // CollectionView setup
        let cv = searchView.collectionView
        cv.dataSource = self
        cv.delegate = self
        cv.register(MovieCell.self, forCellWithReuseIdentifier: "MovieCell")

        // Search field
        searchView.searchField.delegate = self
        searchView.searchField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: false)
//    }
    
    func setupNavbar() {
         let navTitleLabel: UILabel = {
            let l = UILabel()
            l.text = "Search"
            l.font = .custom(.roboto(weight: .bold, size: 30))
            l.textColor = .label
            l.setContentHuggingPriority(.required, for: .horizontal)
            return l
        }()
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(resource: .chevronIcon).withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(customView: backButton),
            UIBarButtonItem(customView: navTitleLabel)
        ]
        
        navigationController?.navigationBar.tintColor = .txt
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Debounced text handling
    @objc private func textChanged(_ sender: UITextField) {
        debounceTimer?.invalidate()
        let q = sender.text ?? ""
        // Before threshold – clear UI and keep labels hidden
        guard q.count >= 3 else {
            movies.removeAll()
            searchView.collectionView.reloadData()
            searchView.resultsLabel.isHidden = true
            searchView.emptyPlaceholder.isHidden = true
            return
        }
        // Debounce: wait 450 ms after last keystroke
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false, block: { [weak self] _ in
            self?.performSearch(query: q)
        })
    }

    private func performSearch(query: String) {
        service.searchMovies(query: query, page: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.movies = response.results
                    self.searchView.collectionView.reloadData()
                    self.updateResultsUI()
                case .failure:
                    self.movies = []
                    self.searchView.collectionView.reloadData()
                    self.updateResultsUI()
                }
            }
        }
    }

    private func updateResultsUI() {
        let count = movies.count
        searchView.resultsLabel.text = "Search results (\(count))"
        searchView.resultsLabel.isHidden = false
        // Show placeholder only when there are zero results
        searchView.emptyPlaceholder.isHidden = count != 0
    }

    // MARK: - Collection DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        cell.configure(movie: movies[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movies[indexPath.item]
        let detailsVM = DetailsViewModel(movieId: movie.id)
        let detailsVC = MovieDetailsHostingController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    // MARK: - Layout sizing like Movies screen
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let inset: CGFloat = 16.5
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let w = (collectionView.bounds.width - inset * 2 - layout.minimumInteritemSpacing) / 2
        return CGSize(width: w, height: w * 1.65)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 16.5, left: 16.5, bottom: 16.5, right: 16.5)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardHeight = frame.height
        self.collectionBottomConstraint?.constant = -keyboardHeight + view.safeAreaInsets.bottom
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        self.collectionBottomConstraint?.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
