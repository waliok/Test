//
//  FavoritesManager.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation
import CoreData

final class FavoritesManager {

    static let shared = FavoritesManager()
    
    private init() {}

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FavoritesStore")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                #if DEBUG
                print("[FavoritesManager] Error loading store: \(error), \(error.userInfo)")
                #endif
            } else {
                #if DEBUG
                print("[FavoritesManager] Store: \(String(describing: storeDescription.url?.path))")
                #endif
            }
        }
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private func saveIfNeeded() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("[FavoritesManager] save error: \(error)")
            #endif
            context.rollback()
        }
    }
}

// MARK: - Public API

extension FavoritesManager {
    
    /// All favorite movie IDs sorted by `addedDate` (newest first).
    var ids: [Int] {
        guard context.persistentStoreCoordinator != nil else { return [] }

        let request: NSFetchRequest<MovieDB> = MovieDB.fetchRequest()
        request.includesPendingChanges = true
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(MovieDB.addedDate), ascending: false)]

        do {
            let objects: [MovieDB] = try context.fetch(request)
            return objects.map { Int($0.iD) }
        } catch {
            #if DEBUG
            print("[FavoritesManager] ids fetch error: \(error)")
            #endif
            return []
        }
    }

    /// Returns true if the movie id is in favorites.
    func isFavorite(_ id: Int) -> Bool {
        guard context.persistentStoreCoordinator != nil else { return false }
        let request: NSFetchRequest<MovieDB> = MovieDB.fetchRequest()
        request.includesPendingChanges = true
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %d", #keyPath(MovieDB.iD), id)
        do {
            return try context.count(for: request) > 0
        } catch {
            #if DEBUG
            print("[FavoritesManager] isFavorite error: \(error)")
            #endif
            return false
        }
    }

    /// Adds the id to favorites (no-op if already present).
    func add(_ id: Int, addedAt: Date = Date()) {
        guard context.persistentStoreCoordinator != nil else { return }
        guard !isFavorite(id) else { return }
        let movie = MovieDB(context: context)
        movie.iD = Int64(id)
        movie.addedDate = addedAt
        saveIfNeeded()
        NotificationCenter.default.post(name: .favoritesChanged, object: nil)
    }

    /// Removes the id from favorites (no-op if not present).
    func remove(_ id: Int) {
        guard context.persistentStoreCoordinator != nil else { return }
        let request: NSFetchRequest<MovieDB> = MovieDB.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %d", #keyPath(MovieDB.iD), id)
        do {
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
            saveIfNeeded()
        } catch {
            #if DEBUG
            print("[FavoritesManager] remove error: \(error)")
            #endif
        }
        NotificationCenter.default.post(name: .favoritesChanged, object: nil)
    }

    /// Toggles presence of the id in favorites.
    func toggle(_ id: Int) {
        isFavorite(id) ? remove(id) : add(id)
    }
}
