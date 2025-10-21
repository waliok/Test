//
//  MovieCell.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import UIKit
import SDWebImage

final class MovieCell: UICollectionViewCell {
    let poster = UIImageView()
    let titleLabel = UILabel()
    let ratingLabel = UILabel()
    private let star = UIButton(type: .system)

    var onToggleFavorite: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.backgroundColor = .secondarySystemBackground

        poster.contentMode = .scaleAspectFill
        poster.clipsToBounds = true
        poster.layer.cornerRadius = 16

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        ratingLabel.font = .preferredFont(forTextStyle: .subheadline)
        ratingLabel.textColor = .secondaryLabel

        star.tintColor = .systemYellow
        star.setImage(UIImage(systemName: "star"), for: .normal)
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
            poster.heightAnchor.constraint(equalTo: poster.widthAnchor, multiplier: 1.5),

            titleLabel.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ratingLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            ratingLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            star.topAnchor.constraint(equalTo: poster.topAnchor, constant: 8),
            star.trailingAnchor.constraint(equalTo: poster.trailingAnchor, constant: -8),
            star.widthAnchor.constraint(equalToConstant: 28),
            star.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(movie: Movie) {
        titleLabel.text = movie.title
        ratingLabel.text = "Rating: \(Int(round(movie.voteAverage ?? 0)))"

        if let p = movie.posterPath {
            let url = URL(string: "https://image.tmdb.org/t/p/w500\(p)")
            poster.sd_setImage(with: url, placeholderImage: nil, options: [.continueInBackground, .retryFailed], completed: nil)
        } else {
            poster.image = nil
        }
        updateStar(isFav: FavoritesManager.shared.isFavorite(movie.id))
        NotificationCenter.default.addObserver(self, selector: #selector(favChanged), name: .favoritesChanged, object: nil)
    }

    @objc private func favChanged() {
        // опционально обновляй звезду если состояние изменилась извне
    }

    @objc private func tapStar() {
        onToggleFavorite?()
        // микро-анимация
        UIView.animate(withDuration: 0.12, animations: {
            self.star.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.12) { self.star.transform = .identity }
        }
        // мгновенно обновим иконку
        if let title = titleLabel.text { /* just to silence unused warning */ _ = title }
    }

    private func updateStar(isFav: Bool) {
        let name = isFav ? "star.fill" : "star"
        star.setImage(UIImage(systemName: name), for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        poster.sd_cancelCurrentImageLoad()
        poster.image = nil
        NotificationCenter.default.removeObserver(self, name: .favoritesChanged, object: nil)
    }
}
