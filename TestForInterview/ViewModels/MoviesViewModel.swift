//
//  MoviesViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation
import os
import QuartzCore


private func logInfo(_ message: String) {
    print("[Movies][Pagination] \(message)")
}

final class MoviesViewModel {
    private let service = MovieService()
    private(set) var movies: [Movie] = []
    private(set) var currentPage = 0
    private(set) var totalPages = Int.max
    private var isLoading = false

    var hasMore: Bool { currentPage < totalPages }

    var onInitialLoading: ((Bool) -> Void)?
    var onBatchAppended: ((_ range: Range<Int>) -> Void)?
    var onError: ((Error) -> Void)?

    func refresh() {
        currentPage = 0
        totalPages = .max
        movies.removeAll()
        onInitialLoading?(true)
        loadNextBatch()
    }

    func loadNextBatch() {
        let startOverall = CACurrentMediaTime()
        func tinfo() -> String {
            let tid = pthread_mach_thread_np(pthread_self())
            return "thread:\(tid)"
        }
        // prevent duplicate loads or loading past the last page
        guard !isLoading, currentPage < totalPages else { return }
        isLoading = true

        // calculate the next two pages to request
        let next1 = currentPage + 1
        let next2 = min(next1 + 1, totalPages)

        let group = DispatchGroup()
        var page1: MovieListResponse?
        var page2: MovieListResponse?
        var firstError: Error?
        var end1: CFTimeInterval = 0
        var end2: CFTimeInterval = 0
        var start2: CFTimeInterval = 0

        // request #1
        let start1 = CACurrentMediaTime()
        logInfo("P\(next1) START \(tinfo()) at \(start1)")
        group.enter()
        service.fetchTopRated(page: next1) { result in
            switch result {
            case .success(let resp):
                page1 = resp
            case .failure(let err):
                firstError = err
            }
            end1 = CACurrentMediaTime()
            let delta1 = end1 - start1
            logInfo("P\(next1) END   \(tinfo()) at \(end1) Δ=\(String(format: "%.2f", delta1))s")
            group.leave()
        }

        // request #2 (only if different from page1)
        if next1 != next2 {
            start2 = CACurrentMediaTime()
            logInfo("P\(next2) START \(tinfo()) at \(start2)")
            group.enter()
            service.fetchTopRated(page: next2) { result in
                switch result {
                case .success(let resp):
                    page2 = resp
                case .failure(let err):
                    if firstError == nil { firstError = err }
                }
                end2 = CACurrentMediaTime()
                let delta2 = end2 - start2
                logInfo("P\(next2) END   \(tinfo()) at \(end2) Δ=\(String(format: "%.2f", delta2))s")
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            if end2 > 0 { // second page requested
                let overlapped = (start2 < end1) && (start1 < end2)
                logInfo("OVERLAP = \(overlapped ? "YES" : "NO")")
            } else {
                logInfo("OVERLAP = N/A (single page)")
            }
            let endOverall = CACurrentMediaTime()
            let total = endOverall - startOverall
            logInfo("BATCH DONE total=\(String(format: "%.2f", total))s")
            guard let self = self else { return }
            self.isLoading = false
            self.onInitialLoading?(false)

            if page1 == nil && page2 == nil, let error = firstError {
                self.onError?(error)
                return
            }

            let start = self.movies.count
            if let p1 = page1 {
                self.currentPage = max(self.currentPage, p1.page)
                self.totalPages = p1.totalPages ?? self.totalPages
                self.movies.append(contentsOf: p1.results)
            }
            if let p2 = page2 {
                self.currentPage = max(self.currentPage, p2.page)
                self.totalPages = p2.totalPages ?? self.totalPages
                self.movies.append(contentsOf: p2.results)
            }
            let end = self.movies.count
            if end > start {
                self.onBatchAppended?(start..<end)
            }
        }
    }
}
