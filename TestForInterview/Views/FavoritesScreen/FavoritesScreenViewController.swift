//
//  FavoritesScreen.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

final class FavoritesScreenViewController: UIViewController {
    private let viewModel = FavoritesScreenViewModel()
    private let contentView = FavoritesScreenView()
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        /// CollectionView setup
        contentView.collectionViewDataSource = self
        contentView.collectionViewDelegate = self
        /// Refresh control
        contentView.refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        bind()
        viewModel.load()
    }
}

// MARK: - UICollectionViewDataSource

extension FavoritesScreenViewController: UICollectionViewDataSource {
    
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

extension FavoritesScreenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        let detailsVM = DetailsScreenViewModel(movieId: movie.id)
        let detailsVC = MovieDetailsHostingController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    // Context menu to remove from favorites
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let movie = viewModel.movies[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let remove = UIAction(title: "Remove from Favorites", image: UIImage(systemName: "heart.slash")) { [weak self] _ in
                self?.viewModel.removeFavorite(id: movie.id)
            }
            return UIMenu(title: "", children: [remove])
        }
    }
}

// MARK: - Other methods

extension FavoritesScreenViewController {
    
    private func setupNavBar() {
        navigationItem.title = "Favorites"
        navigationController?.navigationBar.prefersLargeTitles = false
        let close = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = close
    }
    
    @objc private func closeTapped() { dismiss(animated: true) }
    
    private func bind() {
        viewModel.onLoading = { [weak self] loading in
            self?.contentView.setLoading(loading)
            if !loading { self?.contentView.refreshControl.endRefreshing() }
        }
        viewModel.onReload = { [weak self] in
            guard let self = self else { return }
            self.contentView.reloadData()
            self.contentView.showEmpty(self.viewModel.movies.isEmpty)
        }
        viewModel.onItemsDeleted = { [weak self] idxs in
            guard let self = self else { return }
            let indexPaths = idxs.map { IndexPath(item: $0, section: 0) }
            self.contentView.collectionView.performBatchUpdates({
                self.contentView.collectionView.deleteItems(at: indexPaths)
            }, completion: { _ in
                self.contentView.showEmpty(self.viewModel.movies.isEmpty)
            })
        }
        viewModel.onError = { [weak self] err in
            #if DEBUG
            let message = err.localizedDescription
            #else
            let message = "Something went wrong. Please try again."
            #endif
            let a = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            a.addAction(.init(title: "OK", style: .default))
            self?.present(a, animated: true)
        }
    }
    
    @objc private func onRefresh() { viewModel.load() }
}
