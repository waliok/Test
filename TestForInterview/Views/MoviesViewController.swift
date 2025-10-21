//
//  MoviesViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit

final class MoviesViewController: UIViewController,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegateFlowLayout {
    
    private let viewModel = MoviesViewModel()
    private var collectionView: UICollectionView!
    private let refresh = UIRefreshControl()
    private var isShowingFooter = false
    private let bottomSpinner = UIActivityIndicatorView(style: .medium)
    private var initialHideWorkItem: DispatchWorkItem?
    private var initialShowTime: CFTimeInterval?
    private var firstLoadOverlay: FirstLoadOverlay?
    
    // Nav bar custom views
    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Movie"
        l.font = .systemFont(ofSize: 30, weight: .bold) // 30 bold
        l.textColor = .label
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let avgTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Avg: –"
        l.font = .systemFont(ofSize: 15, weight: .semibold)
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

    private let avgContainer = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bg
        setupNavBar()
        setupCollection()
        setupBottomSpinner()
        bind()
        isShowingFooter = false
        viewModel.refresh()
    }
    
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 16
        let inset: CGFloat = 20
        let w = (view.bounds.width - inset*2 - layout.minimumInteritemSpacing) / 2
        layout.itemSize = CGSize(width: w, height: w * 1.5 + 52)
        layout.sectionInset = UIEdgeInsets(top: 16, left: inset, bottom: 16, right: inset)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: "MovieCell")
        collectionView.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: LoadingFooterView.kind,
            withReuseIdentifier: LoadingFooterView.id
        )
        
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        collectionView.refreshControl = refresh
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    

    private func setupBottomSpinner() {
        bottomSpinner.hidesWhenStopped = true
        bottomSpinner.stopAnimating()
        view.addSubview(bottomSpinner)
        bottomSpinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomSpinner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Loader UI helpers
    private func showInitialLoaderUI() {
        if firstLoadOverlay == nil {
            let overlay = FirstLoadOverlay()
            overlay.show(on: view)
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
        collectionView.alpha = 0
        bottomSpinner.stopAnimating()
    }

    private func hideInitialLoaderUI() {
        firstLoadOverlay?.hideAndRemove()
        firstLoadOverlay = nil
        initialHideWorkItem?.cancel()
        initialHideWorkItem = nil
        initialShowTime = nil
        if collectionView.alpha == 0 {
            UIView.animate(withDuration: 0.25) {
                self.collectionView.alpha = 1
            }
        }
    }

    private func bind() {
        viewModel.onInitialLoading = { [weak self] loading in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isShowingFooter = false
                if loading {
                    if !self.refresh.isRefreshing {
                        self.showInitialLoaderUI()
                        self.collectionView.reloadData()
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
                    self.bottomSpinner.stopAnimating()
                    self.refresh.endRefreshing()
                    self.updateAverageLabel()
                }
            }
        }

        viewModel.onBatchAppended = { [weak self] range in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isShowingFooter = false
                self.refresh.endRefreshing()
                self.bottomSpinner.stopAnimating()
                self.updateAverageLabel()

                // If this is the first batch after a refresh/initial load, do a full reload to avoid batch mismatch
                let currentCount = self.collectionView.numberOfItems(inSection: 0)
                if currentCount == 0 || range.lowerBound == 0 {
                    self.collectionView.reloadData()
                    // ensure footer state updates
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                    return
                }

                let indexPaths = range.map { IndexPath(item: $0, section: 0) }
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: indexPaths)
                }, completion: { _ in
                    // hide footer if there's nothing more to load or after a batch
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                })
            }
        }
        viewModel.onError = { [weak self] err in
            DispatchQueue.main.async {
                self?.bottomSpinner.stopAnimating()
                self?.hideInitialLoaderUI()
                self?.isShowingFooter = false
                self?.refresh.endRefreshing()
                self?.collectionView.reloadSections(IndexSet(integer: 0))
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
    
    // MARK: DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        cell.configure(movie: viewModel.movies[indexPath.item])
        return cell
    }
    
    // MARK: Footer spinner
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == LoadingFooterView.kind {
            let v = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: LoadingFooterView.id, for: indexPath
            ) as! LoadingFooterView
            isShowingFooter ? v.start() : v.stop()
            return v
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        // показываем футер только если есть, что грузить
        if isShowingFooter && viewModel.hasMore {
            return CGSize(width: collectionView.bounds.width, height: 56)
        }
        return .zero
    }
    
    // MARK: Trigger
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore else { return }
        let offsetY = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let height = scrollView.bounds.height
        if offsetY > contentH - height * 1.5 {
            if !isShowingFooter { // show footer and kick off next batch once
                isShowingFooter = true
                collectionView.reloadSections(IndexSet(integer: 0))
                bottomSpinner.startAnimating()
                viewModel.loadNextBatch()
            }
        }
    }
    
    // MARK: - NavBar buttons (Search + Theme)
    private var searchBarButton: UIBarButtonItem {
        let image = UIImage(resource: .searchIcon).withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onSearchTapped))
        return item
    }

    private var themeBarButton: UIBarButtonItem {
        // The asset uses light/dark appearances so it auto-updates when theme changes
        let image = UIImage(resource: .themeIcon).withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onThemeTapped))
        return item
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

        // Keep right buttons
        navigationItem.rightBarButtonItems = [themeBarButton, searchBarButton]

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
        print("Average rating updated to:", String(format: "Avg: %.2f", avg))
        avgTitleLabel.text = String(format: "Avg: %.2f", avg)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAvgTitleSize()
    }

//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        // Re-apply dynamic tint (UIColor.label adapts automatically)
//        navigationController?.navigationBar.tintColor = .label
//        // Ensure images stay templated
//        navigationItem.rightBarButtonItems?.forEach { item in
//            if let img = item.image {
//                item.image = img.withRenderingMode(.alwaysTemplate)
//            }
//        }
//    }

    @objc private func onThemeTapped() {
        ThemeManager.shared.toggleTheme()
    }

    @objc private func onSearchTapped() {
        presentSearch()
    }

    /// Stub for search flow; replace with your real search screen
    private func presentSearch() {
        let alert = UIAlertController(title: "Search", message: "Hook up your search screen here.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Movie title" }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "OK", style: .default, handler: { [weak alert] _ in
            let query = alert?.textFields?.first?.text ?? ""
            // TODO: forward query to viewModel.search(query:)
            print("Search query:", query)
        }))
        present(alert, animated: true)
    }
}
