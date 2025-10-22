//
//  MoviesViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation
import QuartzCore
import Combine

private func logInfo(_ message: String) {
    print("[Movies][Pagination] \(message)")
}

final class MoviesScreenViewModel {
    private let service = MovieService()
    private(set) var movies: [Movie] = []
    private(set) var currentPage = 0
    private(set) var totalPages = Int.max
    private var isLoading = false

    private var pendingOfflineAlert: DispatchWorkItem?

    var hasMore: Bool { currentPage < totalPages }

    var onInitialLoading: ((Bool) -> Void)?
    var onBatchAppended: ((_ range: Range<Int>) -> Void)?
    var onError: ((Error) -> Void)?
    let alertSubject = PassthroughSubject<AlertType, Never>()

    func refresh() {
        pendingOfflineAlert?.cancel()
        pendingOfflineAlert = nil
        onInitialLoading?(true)
        guard NetworkMonitor.shared.isConnected else {
            print("No Internet Connection")
            let work = DispatchWorkItem { [weak self] in
                self?.alertSubject.send(.noInternet)
                self?.onInitialLoading?(false)
                self?.pendingOfflineAlert = nil
            }
            pendingOfflineAlert = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
            return
        }
        currentPage = 0
        totalPages = .max
        movies.removeAll()
        loadNextBatch()
    }

    /**
     /// Loads the next batch of movies with pagination.
     /// - Requests two pages concurrently (page N+1 and N+2) using a DispatchGroup.
     /// - Logs timing info for each request to measure overlap and total duration.
     /// - Prevents duplicate or out-of-range loads using `isLoading` and `currentPage` guards.
     /// - On completion:
     ///   - Merges results of both pages into the main movie list.
     ///   - Updates `currentPage` and `totalPages` based on server response.
     ///   - Notifies observers via `onBatchAppended` for new range of movies.
     ///   - Sends `onInitialLoading(false)` when done and calls `onError` if both failed.
     */
    func loadNextBatch() {
        guard NetworkMonitor.shared.isConnected else {
            print("No Internet Connection")
            alertSubject.send(.noInternet)
            onInitialLoading?(false)
            return
        }
        // Prevent duplicate loads or loading past the last page
        guard !isLoading, hasMore else { return }
        isLoading = true

        // Determine pages to request
        let next1 = currentPage + 1
        let next2 = next1 + 1
        let shouldRequestSecond = next2 <= totalPages

        // Profiler for timing/overlap logs
        let startOverall = CACurrentMediaTime()
        var startTimes: [Int: CFTimeInterval] = [:]
        func start(_ page: Int) { startTimes[page] = CACurrentMediaTime(); logInfo("P\(page) START thread:\(pthread_mach_thread_np(pthread_self())) at \(startTimes[page]!)") }
        func end(_ page: Int) {
            let end = CACurrentMediaTime()
            let delta = end - (startTimes[page] ?? end)
            logInfo("P\(page) END   thread:\(pthread_mach_thread_np(pthread_self())) at \(end) Δ=\(String(format: "%.2f", delta))s")
        }

        // Aggregation
        let group = DispatchGroup()
        var page1: MovieListResponse?
        var page2: MovieListResponse?
        var firstError: Error?

        // Request #1
        group.enter()
        start(next1)
        service.fetchTopRated(page: next1) { result in
            switch result {
            case .success(let resp): page1 = resp
            case .failure(let err): firstError = err
            }
            end(next1)
            group.leave()
        }

        // Request #2 (optional)
        if shouldRequestSecond {
            group.enter()
            start(next2)
            service.fetchTopRated(page: next2) { result in
                switch result {
                case .success(let resp): page2 = resp
                case .failure(let err): if firstError == nil { firstError = err }
                }
                end(next2)
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            defer {
                self.isLoading = false
                self.onInitialLoading?(false)
            }

            // Overlap + total timing
            if shouldRequestSecond, let s1 = startTimes[next1], let s2 = startTimes[next2] {
                // We approximatively infer overlap by comparing start times; detailed end times are logged above
                logInfo("OVERLAP = \(s2 < CACurrentMediaTime() && s1 < CACurrentMediaTime() ? "YES" : "N/A")")
            } else {
                logInfo("OVERLAP = N/A (single page)")
            }
            let total = CACurrentMediaTime() - startOverall
            logInfo("BATCH DONE total=\(String(format: "%.2f", total))s")

            // If both failed, surface error
            if page1 == nil && page2 == nil, let error = firstError {
                self.onError?(error)
                if self.movies.isEmpty { // initial load: keep loader for ~3s first
                    self.pendingOfflineAlert?.cancel()
                    let work = DispatchWorkItem { [weak self] in
                        self?.alertSubject.send(.error(error.localizedDescription))
                        self?.onInitialLoading?(false)
                        self?.pendingOfflineAlert = nil
                    }
                    self.pendingOfflineAlert = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
                } else {
                    // pagination case: show error right away (no initial overlay)
                    self.alertSubject.send(.error(error.localizedDescription))
                    self.onInitialLoading?(false)
                }
                return
            }

            // Append results in page order to preserve list consistency
            let startIndex = self.movies.count
            if let p1 = page1 { self.append(p1) }
            if let p2 = page2 { self.append(p2) }
            let endIndex = self.movies.count
            if endIndex > startIndex {
                // Cancel any scheduled offline alert because we have data
                self.pendingOfflineAlert?.cancel()
                self.pendingOfflineAlert = nil
                self.onBatchAppended?(startIndex..<endIndex)
            }
        }
    }

    private func append(_ response: MovieListResponse) {
        // Update pagination bounds first
        currentPage = max(currentPage, response.page)
        if let tp = response.totalPages { totalPages = tp }
        // Append avoiding accidental duplicates by id (defensive)
        if movies.isEmpty {
            movies.append(contentsOf: response.results)
            return
        }
        let existing = Set(movies.map { $0.id })
        let newOnes = response.results.filter { !existing.contains($0.id) }
        movies.append(contentsOf: newOnes)
    }
}
