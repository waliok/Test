//
//  MovieCell.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit
import SDWebImage

final class MovieCell: CustomUICollectionViewCell {
    
    private var movieID: Int?
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .tertiarySystemFill
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(.roboto(weight: .semibold, size: 14))
        label.textColor = .txt
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(.roboto(weight: .medium, size: 10))
        label.textColor = .txt
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var starButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(resource: .favOffIcon).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(tapStar), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var onToggleFavorite: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.sd_cancelCurrentImageLoad()
        posterImageView.image = nil
        titleLabel.text = nil
        ratingLabel.text = nil
        NotificationCenter.default.removeObserver(self, name: .favoritesChanged, object: nil)
    }
    
    override func setupUI() {
        super.setupUI()
        contentView.layer.cornerRadius = 15
        contentView.backgroundColor = .clear
        containerView.layer.cornerRadius = 15
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func setupLayout() {
        super.setupLayout()
        
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        containerView.add(subviews: posterImageView, titleLabel, ratingLabel, starButton)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            ratingLabel.heightAnchor.constraint(equalToConstant: 16),
            ratingLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            ratingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            starButton.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 11),
            starButton.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: -14),
            starButton.widthAnchor.constraint(equalToConstant: 28),
            starButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}

// MARK: - Configure cell

extension MovieCell {
    func configure(movie: Movie) {
        movieID = movie.id
        titleLabel.text = movie.title
        ratingLabel.text = "Rating: \(Int(round(movie.voteAverage ?? 0)))"
        let indicator = ThemeManager.shared.current == .dark
        ? SDWebImageActivityIndicator.whiteLarge
        : SDWebImageActivityIndicator.grayLarge
        posterImageView.tintColor = UIColor.secondaryLabel
        posterImageView.sd_imageIndicator = indicator
        posterImageView.sd_imageIndicator?.startAnimatingIndicator()
        posterImageView.sd_imageTransition = .fade
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        let placeholderIMG = UIImage(systemName: "photo.fill.on.rectangle.fill", withConfiguration: symbolConfig)
        posterImageView.image = placeholderIMG
        
        posterImageView.sd_setImage(
            with: movie.fullPosterURL,
            placeholderImage: nil,
            options: [.retryFailed, .scaleDownLargeImages, .continueInBackground]
        ) { [weak self] image, error, _, _ in
            guard let self = self else { return }
            self.posterImageView.sd_imageIndicator?.stopAnimatingIndicator()
            if image != nil && error == nil {
                self.posterImageView.contentMode = .scaleAspectFill
                self.posterImageView.backgroundColor = .clear
            } else {
                self.posterImageView.contentMode = .scaleAspectFit
                self.posterImageView.image = placeholderIMG
                self.posterImageView.backgroundColor = UIColor.tertiarySystemFill
            }
        }
        
        updateStar(isFav: FavoritesManager.shared.isFavorite(movie.id))
        NotificationCenter.default.addObserver(self, selector: #selector(favChanged), name: .favoritesChanged, object: nil)
    }
}

// MARK: - OtherMethods

extension MovieCell {
    
    @objc private func favChanged() {
        guard let movieID = movieID else { return }
        let isFav = FavoritesManager.shared.isFavorite(movieID)
        updateStar(isFav: isFav)
    }

    @objc private func tapStar() {
        // Bounce animation (safe weak self to avoid retaining cell longer than needed)
        UIView.animate(withDuration: 0.12, animations: { [weak self] in
            self?.starButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.12) { [weak self] in
                self?.starButton.transform = .identity
            }
        }

        // Toggle favorite either via external handler (preferred) or locally when handler is absent
        if let onToggleFavorite = onToggleFavorite {
            onToggleFavorite()
        } else if let movieID = movieID {
            FavoritesManager.shared.toggle(movieID)
        }
    }

    private func updateStar(isFav: Bool) {
        let image = isFav ? UIImage(resource: .favOnIcon) : UIImage(resource: .favOffIcon)
        starButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
    }
}
