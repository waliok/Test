//
//  MoviesViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//


import UIKit
import Combine

final class MoviesScreenViewController: UIViewController {
    
    private let viewModel = MoviesScreenViewModel()
    private let contentView = MoviesScreenView()
    private var isShowingFooter = false
    private var initialHideWorkItem: DispatchWorkItem?
    private var initialShowTime: CFTimeInterval?
    private var firstLoadOverlay: FirstLoadOverlay?
    private var cancellables = Set<AnyCancellable>()
    
    // Nav bar custom views
    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Movie"
        l.font = .custom(.roboto(weight: .bold, size: 30))
        l.textColor = .label
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()
    
    private let avgTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Avg: –"
        l.font = .custom(.roboto(weight: .semibold, size: 16))
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.lineBreakMode = .byClipping
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    
    // MARK: - NavBar buttons (Search + Theme)
    private lazy var themeItem: UIBarButtonItem = {
        let image = UIImage(resource: .lightThemeIcon).withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onThemeTapped))
        return item
    }()
    
    private var searchBarButton: UIBarButtonItem {
        let image = UIImage(resource: .searchIcon).withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onSearchTapped))
        return item
    }
    
    private var favoritesBarButton: UIBarButtonItem {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(resource: .favOnIcon).withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = .txt
        btn.addTarget(self, action: #selector(onFavoritesTapped), for: .touchUpInside)
        let item = UIBarButtonItem(customView: btn)
        self.favoritesButtonView = btn
        return item
    }
    
    private let avgContainer = UIView()
    private weak var favoritesButtonView: UIView?
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                guard let self = self else { return }
                switch alert {
                case .noInternet:
                    let retry = UIAlertAction(title: "Retry", style: .default) { _ in
                        self.viewModel.refresh()
                    }
                    let cancel = UIAlertAction.cancel
                    self.showAlertWithActions(title: "No Internet", message: "Please check your connection and try again.", actions: [retry, cancel])
                case .error(let message):
                    self.showError(message: message)
                }
            }
            .store(in: &cancellables)
        
        setupNavBar()
        // CollectionView setup
        contentView.collectionViewDataSource = self
        contentView.collectionViewDelegate = self
        // Pull-to-refresh target
        contentView.refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        bind()
        isShowingFooter = false
        viewModel.refresh()
        updateThemeIcon()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAvgTitleSize()
    }
}

// MARK: - UICollectionViewDataSource

extension MoviesScreenViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(reusable: MovieCell.self, for: indexPath)
        cell.configure(movie: viewModel.movies[indexPath.item])
        return cell
    }
    
    // MARK: Footer spinner
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueHeaderFooterView(of: UICollectionView.elementKindSectionFooter, reusable: LoadingFooterView.self, for: indexPath)
        isShowingFooter ? footer.start() : footer.stop()
        return footer
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if isShowingFooter && viewModel.hasMore {
            return CGSize(width: collectionView.bounds.width, height: 56)
        }
        return .zero
    }
}

// MARK: - UICollectionViewDelegate

extension MoviesScreenViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        let detailsVM = DetailsScreenViewModel(movieId: movie.id)
        let detailsVC = MovieDetailsHostingController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore else { return }
        let offsetY = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let height = scrollView.bounds.height
        if offsetY > contentH - height * 1.5 {
            if !isShowingFooter { // show footer and kick off next batch once
                isShowingFooter = true
                contentView.reloadSection(0)
                contentView.startBottomSpinner()
                viewModel.loadNextBatch()
            }
        }
    }
}

// MARK: - Other methods

extension MoviesScreenViewController {
    // MARK: - Loader UI helpers
    private func showInitialLoaderUI() {
        if firstLoadOverlay == nil {
            let overlay = FirstLoadOverlay()
            let hostView: UIView = self.navigationController?.view ?? self.view
            overlay.show(on: hostView)
            hostView.bringSubviewToFront(overlay)
            firstLoadOverlay = overlay
            // remember show time and schedule guaranteed hide in 3s
            initialShowTime = CACurrentMediaTime()
            initialHideWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.hideInitialLoaderUI()
                self?.initialHideWorkItem = nil
                self?.initialShowTime = nil
            }
            initialHideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
        }
        contentView.collectionView.alpha = 0
        contentView.stopBottomSpinner()
    }
    
    private func hideInitialLoaderUI() {
        firstLoadOverlay?.hideAndRemove()
        firstLoadOverlay = nil
        initialHideWorkItem?.cancel()
        initialHideWorkItem = nil
        initialShowTime = nil
        if contentView.collectionView.alpha == 0 {
            UIView.animate(withDuration: 0.25) {
                self.contentView.collectionView.alpha = 1
            }
        }
    }
    
    private func bind() {
        viewModel.onInitialLoading = { [weak self] loading in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isShowingFooter = false
                if loading {
                    if !self.contentView.refreshControl.isRefreshing {
                        self.showInitialLoaderUI()
                        self.contentView.reloadData()
                    }
                } else {
                    // Respect minimum 3s display: if shown < 3s ago, let scheduled work item hide it; otherwise hide now
                    if let started = self.initialShowTime {
                        let elapsed = CACurrentMediaTime() - started
                        if elapsed >= 3 {
                            self.hideInitialLoaderUI()
                        }
                    } else {
                        self.hideInitialLoaderUI()
                    }
                    self.contentView.stopBottomSpinner()
                    self.contentView.refreshControl.endRefreshing()
                    self.updateAverageLabel()
                }
            }
        }
        
        viewModel.onBatchAppended = { [weak self] range in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isShowingFooter = false
                self.contentView.refreshControl.endRefreshing()
                self.contentView.stopBottomSpinner()
                self.updateAverageLabel()
                
                // If this is the first batch after a refresh/initial load, do a full reload to avoid batch mismatch
                let currentCount = self.contentView.numberOfItemsInSection(0)
                if currentCount == 0 || range.lowerBound == 0 {
                    self.contentView.reloadData()
                    // ensure footer state updates
                    self.contentView.reloadSection(0)
                    return
                }
                
                let indexPaths = range.map { IndexPath(item: $0, section: 0) }
                self.contentView.collectionView.performBatchUpdates({
                    self.contentView.collectionView.insertItems(at: indexPaths)
                }, completion: { _ in
                    // hide footer if there's nothing more to load or after a batch
                    self.contentView.reloadSection(0)
                })
            }
        }
        viewModel.onError = { [weak self] err in
            DispatchQueue.main.async {
                self?.contentView.stopBottomSpinner()
                self?.hideInitialLoaderUI()
                self?.isShowingFooter = false
                self?.contentView.refreshControl.endRefreshing()
                self?.contentView.reloadSection(0)
                let debugMessage: String
                #if DEBUG
                debugMessage = err.localizedDescription
                #else
                debugMessage = "Something went wrong. Please try again."
                #endif
                let a = UIAlertController(title: "Error", message: debugMessage, preferredStyle: .alert)
                a.addAction(.init(title: "OK", style: .default))
                self?.present(a, animated: true)
            }
        }
    }
    
    @objc private func onRefresh() {
        isShowingFooter = false
        viewModel.refresh()
    }
    
    private func setupNavBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // Make nav bar buttons follow dynamic color
        navigationController?.navigationBar.tintColor = .txt
        
        // Left-aligned big title label
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navTitleLabel)
        
        // Center title shows average rating for all loaded movies
        avgContainer.subviews.forEach { $0.removeFromSuperview() }
        avgContainer.translatesAutoresizingMaskIntoConstraints = true // frame-based inside nav bar
        avgContainer.addSubview(avgTitleLabel)
        avgTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avgTitleLabel.topAnchor.constraint(equalTo: avgContainer.topAnchor),
            avgTitleLabel.leadingAnchor.constraint(equalTo: avgContainer.leadingAnchor),
            avgTitleLabel.bottomAnchor.constraint(equalTo: avgContainer.bottomAnchor),
            avgTitleLabel.trailingAnchor.constraint(equalTo: avgContainer.trailingAnchor)
        ])
        navigationItem.titleView = avgContainer
        
        navigationItem.rightBarButtonItems = [favoritesBarButton, themeItem, searchBarButton]
        
        // Initial average
        updateAverageLabel()
    }
    
    /// Updates the average rating label from all currently loaded movies
    private func updateAverageLabel() {
        // Use only non-nil ratings from Movie.voteAverage
        let ratings: [Double] = viewModel.movies.compactMap { $0.voteAverage }
        guard !ratings.isEmpty else {
            avgTitleLabel.text = "Avg: –"
            updateAvgTitleSize()
            avgTitleLabel.setNeedsLayout()
            return
        }
        let sum = ratings.reduce(0.0, +)
        let avg = sum / Double(ratings.count)
        avgTitleLabel.text = String(format: "Avg Rating: %.2f", avg)
        updateAvgTitleSize()
        avgTitleLabel.setNeedsLayout()
    }
    
    private func updateAvgTitleSize() {
        // Ask Auto Layout for the tightest size that fits and apply it to the container's bounds
        let target = CGSize(width: UIView.layoutFittingCompressedSize.width,
                            height: UIView.layoutFittingCompressedSize.height)
        let size = avgTitleLabel.systemLayoutSizeFitting(target)
        avgContainer.bounds = CGRect(origin: .zero, size: size)
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    private func updateThemeIcon() {
        let isDark = traitCollection.userInterfaceStyle == .dark
            let img: UIImage = isDark
                ? UIImage(resource: .darkThemeIcon)
                : UIImage(resource: .lightThemeIcon)
            themeItem.image = img.withRenderingMode(.alwaysTemplate)
    }
    
    @objc private func onThemeTapped() {
        ThemeManager.shared.toggleTheme()
        DispatchQueue.main.async { [weak self] in
            self?.updateThemeIcon()
        }
    }
    
    @objc private func onSearchTapped() {
        presentSearchScreen()
    }
    
    @objc private func onFavoritesTapped() {
        let favVC = FavoritesScreenViewController()
        let nav = UINavigationController(rootViewController: favVC)
        nav.modalPresentationStyle = .custom
        
        let delegate = FavoritesTransitioningDelegate.shared
        if let button = favoritesButtonView, let win = view.window {
            let frameInWindow = button.convert(button.bounds, to: win)
            delegate.originFrame = frameInWindow
        } else {
            // запасной вариант, если по какой-то причине кнопка недоступна
            delegate.originFrame = CGRect(x: view.bounds.midX, y: view.safeAreaInsets.top + 10, width: 44, height: 44)
        }
        nav.transitioningDelegate = delegate
        present(nav, animated: true)
    }
    
    private func presentSearchScreen() {
        let vc = SearchScreenViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateThemeIcon()
        }
    }
}
