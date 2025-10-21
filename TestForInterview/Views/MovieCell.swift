//
//  MovieCell.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit
import SDWebImage

final class MovieCell: UICollectionViewCell {
    var movieID: Int?
    let poster = UIImageView()
    let titleLabel = UILabel()
    let ratingLabel = UILabel()
    private let star = UIButton(type: .system)

    var onToggleFavorite: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 15
        contentView.backgroundColor = .clear

        poster.contentMode = .scaleAspectFill
        poster.clipsToBounds = true
        poster.layer.cornerRadius = 15

        titleLabel.font = .custom(.roboto(weight: .semibold, size: 14))
        titleLabel.textColor = .txt
        ratingLabel.font = .custom(.roboto(weight: .medium, size: 10))
        ratingLabel.textColor = .txt

        star.setImage(UIImage(resource: .favOffIcon).withRenderingMode(.alwaysOriginal), for: .normal)
        star.addTarget(self, action: #selector(tapStar), for: .touchUpInside)

        contentView.addSubview(poster)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(star)

        poster.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        star.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            poster.topAnchor.constraint(equalTo: contentView.topAnchor),
            poster.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            poster.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            poster.heightAnchor.constraint(equalTo: poster.widthAnchor, multiplier: 1.43),

            titleLabel.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ratingLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            ratingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            star.topAnchor.constraint(equalTo: poster.topAnchor, constant: 11),
            star.trailingAnchor.constraint(equalTo: poster.trailingAnchor, constant: -14),
            star.widthAnchor.constraint(equalToConstant: 28),
            star.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(movie: Movie) {
        movieID = movie.id
        titleLabel.text = movie.title
        ratingLabel.text = "Rating: \(Int(round(movie.voteAverage ?? 0)))"
        poster.sd_setImage(with: movie.fullPosterURL, placeholderImage: nil, options: [.continueInBackground, .retryFailed], completed: nil)
        
        updateStar(isFav: FavoritesManager.shared.isFavorite(movie.id))
        NotificationCenter.default.addObserver(self, selector: #selector(favChanged), name: .favoritesChanged, object: nil)
    }

    @objc private func favChanged() {
        guard let movieID = movieID else { return }
        let isFav = FavoritesManager.shared.isFavorite(movieID)
        updateStar(isFav: isFav)
    }

    @objc private func tapStar() {
        onToggleFavorite?()
        // микро-анимация
        UIView.animate(withDuration: 0.12, animations: {
            self.star.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            guard let movieID = self.movieID else { return }
            FavoritesManager.shared.toggle(movieID)
        }) { _ in
            UIView.animate(withDuration: 0.12) { self.star.transform = .identity }
        }
        // мгновенно обновим иконку
        if let title = titleLabel.text { /* just to silence unused warning */ _ = title }
    }

    private func updateStar(isFav: Bool) {
        let image = isFav ? UIImage(resource: .favOnIcon) : UIImage(resource: .favOffIcon)
        star.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        poster.sd_cancelCurrentImageLoad()
        poster.image = nil
        NotificationCenter.default.removeObserver(self, name: .favoritesChanged, object: nil)
    }
}
