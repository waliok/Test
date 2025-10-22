//
//  UICollectionView+DeqReuse.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit

extension UICollectionReusableView {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

extension UICollectionView {
    func register<T: UICollectionViewCell>(cell: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UICollectionReusableView>(header: T.Type) {
        register(T.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UICollectionReusableView>(footer: T.Type) {
        register(T.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: T.reuseIdentifier)
    }

    func dequeue<T: UICollectionViewCell>(reusable identifier: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            // Log the error or handle it appropriately
            print("Failed to dequeue cell with identifier: \(T.reuseIdentifier)")
            return T() // Return a new instance of T
        }
        return cell
    }

    func dequeue<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            // Log the error or handle it appropriately
            print("Failed to dequeue cell with identifier: \(T.reuseIdentifier)")
            return T() // Return a new instance of T
        }
        return cell
    }

    func dequeueHeaderFooterView<T: UICollectionReusableView>(of kind: String, reusable identifier: T.Type, for indexPath: IndexPath) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Unable to dequeue reusable header/footer view with identifier: \(T.reuseIdentifier)")
        }
        return view
    }
}
