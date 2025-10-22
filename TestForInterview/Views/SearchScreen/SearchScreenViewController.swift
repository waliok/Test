//
//  SearchScreenViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit
import Combine
import Network


final class SearchScreenViewController: UIViewController {

    private let viewModel: SearchScreenViewModel
    private var cancellables = Set<AnyCancellable>()

    private var contentView = SearchScreenView()
    private var collectionBottomConstraint: NSLayoutConstraint?

    // Expose a Combine publisher for text changes
    private var searchTextPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: contentView.searchField)
            .compactMap { ($0.object as? UITextField)?.text }
            .eraseToAnyPublisher()
    }

    // MARK: - Inits

    init(viewModel: SearchScreenViewModel = SearchScreenViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Use custom view
    override func loadView() {
        super.loadView()
        view = contentView
        collectionBottomConstraint = contentView.collectionBottomConstraint
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()

        /// CollectionView setup
        contentView.collectionViewDataSource = self
        contentView.collectionViewDelegate = self

        /// Search field
        contentView.searchFieldDelegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        viewModel.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                guard let self = self else { return }
                switch alert {
                case .noInternet:
                    let retry = UIAlertAction(title: "Retry", style: .default) { _ in
                        self.viewModel.submitSearch(self.contentView.searchField.text ?? "")
                    }
                    let cancel = UIAlertAction.cancel
                    self.showAlertWithActions(title: "No Internet", message: "Please check your connection and try again.", actions: [retry, cancel])
                case .error(let message):
                    self.showError(message: message)
                }
            }
            .store(in: &cancellables)

        // Bind VC -> VM (inputs)
        searchTextPublisher
            .sink { [weak self] text in
                self?.viewModel.queryInput.send(text)
            }
            .store(in: &cancellables)

        // Bind VM -> VC (outputs)
        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.contentView.reloadCollectionView()
            }
            .store(in: &cancellables)

        viewModel.$resultsCount
            .receive(on: RunLoop.main)
            .sink { [weak self] count in
                self?.contentView.setResultsCount(count)
            }
            .store(in: &cancellables)

        viewModel.$showResultsLabel
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.contentView.hideResultsLabel(!show)
            }
            .store(in: &cancellables)

        viewModel.$showEmptyPlaceholder
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.contentView.hideEmptyPlaceholder(!show)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UICollectionViewDataSource

extension SearchScreenViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(reusable: MovieCell.self, for: indexPath)
        cell.configure(movie: viewModel.movies[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SearchScreenViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        let detailsVM = DetailsScreenViewModel(movieId: movie.id)
        let detailsVC = MovieDetailsHostingController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension SearchScreenViewController: UITextFieldDelegate  {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let q = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.submitSearch(q)
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        // Clearing returns the UI to idle state via VM
        viewModel.queryInput.send("")
        return true
    }
}

// MARK: - OtherMethods

extension SearchScreenViewController {

    private func setupNavbar() {
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

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Keyboard handling

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
}
