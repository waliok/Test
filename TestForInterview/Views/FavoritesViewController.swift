//
//  FavoritesViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import Foundation

//
//  FavoritesViewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//


import UIKit

final class FavoritesInteractor: UIPercentDrivenInteractiveTransition {
    var isInteractive = false
}

final class FavoritesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var isApplyingLocalMutation = false
    private var collectionView: UICollectionView!
    private let spinner = UIActivityIndicatorView(style: .large)
    private let emptyStack = UIStackView()

    private var movies: [Movie] = []
    private let service = MovieService()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bg
        setupNavBar()
        setupCollection()
        setupEmptyState()
        setupSpinner()
        NotificationCenter.default.addObserver(self, selector: #selector(onFavoritesChanged), name: .favoritesChanged, object: nil)
        loadFavorites()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupNavBar() {
        // Small title with close button
        navigationItem.title = "Favorites"
        navigationController?.navigationBar.prefersLargeTitles = false
        let close = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = close
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let inset: CGFloat = 16.5
        let w = (view.bounds.width - inset*2 - layout.minimumInteritemSpacing) / 2
        layout.itemSize = CGSize(width: w, height: w * 1.65)
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: "MovieCell")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStack.axis = .vertical
        emptyStack.alignment = .center
        emptyStack.spacing = 12

        let iv = UIImageView(image: UIImage(resource: .emptyListPlaceholderIcon))
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .vertical)
        iv.setContentHuggingPriority(.required, for: .horizontal)
        let label = UILabel()
        label.text = "No favorites yet"
        label.font = .custom(.roboto(weight: .semibold, size: 16))
        label.textColor = .secondaryLabel
        emptyStack.addArrangedSubview(iv)
        emptyStack.addArrangedSubview(label)

        view.addSubview(emptyStack)
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 120),
            iv.heightAnchor.constraint(equalToConstant: 120)
        ])
        emptyStack.isHidden = true
    }

    // MARK: - Data
    @objc private func onFavoritesChanged() {
        guard !isApplyingLocalMutation else { return }
        loadFavorites()
    }

    private func loadFavorites() {
        let ids = Array(FavoritesManager.shared.ids)
        applyLoading(true)
        movies.removeAll()
        collectionView.reloadData()

        guard !ids.isEmpty else {
            applyLoading(false)
            showEmpty(true)
            return
        }

        let group = DispatchGroup()
        var loaded: [Movie] = []
        var seen = Set<Int>()
        ids.forEach { id in
            group.enter()
            service.fetchMovieDetails(id: id) { result in
                if case let .success(details) = result {
                    // Map MovieDetails to Movie struct if needed, otherwise try to cast/convert
                    let movie = Movie(id: details.id, title: details.title, overview: details.overview, posterPath: details.posterPath, releaseDate: details.releaseDate, voteAverage: details.voteAverage)
                    if !seen.contains(movie.id) { loaded.append(movie); seen.insert(movie.id) }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.movies = loaded.sorted { ($0.title) < ($1.title) }
            self.collectionView.reloadData()
            self.applyLoading(false)
            self.showEmpty(self.movies.isEmpty)
        }
    }

    private func applyLoading(_ loading: Bool) {
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    private func showEmpty(_ show: Bool) {
        emptyStack.isHidden = !show
        collectionView.isHidden = show
    }

    // MARK: - DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        cell.configure(movie: movies[indexPath.item])
        return cell
    }

    // MARK: - Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movies[indexPath.item]
        let detailsVM = DetailsViewModel(movieId: movie.id)
        let detailsVC = MovieDetailsHostingController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    // Context menu to remove from favorites
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let movie = movies[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let remove = UIAction(title: "Remove from Favorites", image: UIImage(systemName: "heart.slash")) { _ in
                self.isApplyingLocalMutation = true
                // Update model & UI atomically and consistently with the collection view
                DispatchQueue.main.async {
                    if let idx = self.movies.firstIndex(where: { $0.id == movie.id }) {
                        self.collectionView.performBatchUpdates({
                            self.movies.remove(at: idx)
                            self.collectionView.deleteItems(at: [IndexPath(item: idx, section: 0)])
                        }, completion: { _ in
                            self.showEmpty(self.movies.isEmpty)
                            self.isApplyingLocalMutation = false
                        })
                    } else {
                        // Fallback: just reload
                        self.collectionView.reloadData()
                        self.showEmpty(self.movies.isEmpty)
                        self.isApplyingLocalMutation = false
                    }
                }
                // Persist removal (will post notification, but it's suppressed by the flag)
                FavoritesManager.shared.remove(movie.id)
            }
            return UIMenu(title: "", children: [remove])
        }
    }
}

// MARK: - Custom Transition: Grow-from-Source Animation
//
// Presents the Favorites screen by scaling it up from the Favorites button’s position.
// The transition uses a spring-based scale transform (0.02 → 1.0) and centers
// around the button’s midpoint for a smooth "expanding modal" effect.
// On dismissal, the view shrinks back into the button with matching spring dynamics.

final class FavoritesTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = FavoritesTransitioningDelegate()
    var originFrame: CGRect = .zero

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FavoritesPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FavoritesGrowAnimator(isPresenting: true, originFrame: originFrame)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FavoritesGrowAnimator(isPresenting: false, originFrame: originFrame)
    }
}

private final class FavoritesPresentationController: UIPresentationController {
    private let blurView = UIVisualEffectView(effect: nil)

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        blurView.addGestureRecognizer(tap)
    }

    @objc private func dismissSelf() { presentedViewController.dismiss(animated: true) }

    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView?.bounds ?? .zero
    }

    override func presentationTransitionWillBegin() {
        guard let cv = containerView else { return }
        blurView.frame = cv.bounds
        cv.insertSubview(blurView, at: 0)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = UIBlurEffect(style: .systemMaterialDark)
        })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = nil
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        blurView.frame = containerView?.bounds ?? .zero
    }
}

private final class FavoritesGrowAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let originFrame: CGRect
    init(isPresenting: Bool, originFrame: CGRect) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0.65 : 0.55
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        // Translate origin (window coords) to container coords
        let originInContainer = container.convert(originFrame, from: nil)
        let originCenter = CGPoint(x: originInContainer.midX, y: originInContainer.midY)

        if isPresenting {
            guard let toVC = transitionContext.viewController(forKey: .to),
                  let toView = transitionContext.view(forKey: .to) else { return }

            let finalFrame = transitionContext.finalFrame(for: toVC)
            let finalCenter = CGPoint(x: finalFrame.midX, y: finalFrame.midY)

            // Prepare view
            toView.frame = finalFrame
            toView.layer.masksToBounds = true
            toView.layer.cornerRadius = 12
            container.addSubview(toView)

            // Start from button center + scale
            let sx = max(0.02, originInContainer.width / max(1, finalFrame.width))
            let sy = max(0.02, originInContainer.height / max(1, finalFrame.height))
            toView.transform = CGAffineTransform(scaleX: sx, y: sy)
            toView.center = originCenter

            // Animate to identity
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.35,
                           options: [.curveEaseInOut],
                           animations: {
                toView.transform = .identity
                toView.center = finalCenter
                toView.layer.cornerRadius = 0
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            let startCenter = fromView.center

            let fullFrame = transitionContext.containerView.bounds
            let sx = max(0.02, originInContainer.width / max(1, fullFrame.width))
            let sy = max(0.02, originInContainer.height / max(1, fullFrame.height))

            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.95,
                           initialSpringVelocity: 0.0,
                           options: [.curveEaseInOut],
                           animations: {
                fromView.transform = CGAffineTransform(scaleX: sx, y: sy)
                fromView.center = originCenter
                fromView.layer.cornerRadius = 12
            }, completion: { finished in
                // Reset any transforms to avoid affecting reusable views
                fromView.transform = .identity
                fromView.center = startCenter
                transitionContext.completeTransition(finished)
            })
        }
    }
}
