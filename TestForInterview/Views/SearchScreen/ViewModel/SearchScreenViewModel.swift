//
//  SearchScreenViewModel.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import Foundation
import Combine
import Network

final class SearchScreenViewModel {
    // Inputs
    let queryInput = CurrentValueSubject<String, Never>("")

    // Outputs (read-only for the ViewController)
    @Published private(set) var movies: [Movie] = []
    @Published private(set) var resultsCount: Int = 0
    @Published private(set) var showResultsLabel: Bool = false
    @Published private(set) var showEmptyPlaceholder: Bool = false

    let alertSubject = PassthroughSubject<AlertType, Never>()

    // Private
    private let service: MovieService
    private var lastIssuedQuery: String?
    private var cancellables = Set<AnyCancellable>()

    init(service: MovieService = MovieService()) {
        self.service = service
        bind()
    }

    private func bind() {
        // Debounce and sanitize query input here (in VM)
        queryInput
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleQuery(text)
            }
            .store(in: &cancellables)
    }

    func submitSearch(_ text: String) {
        handleQuery(text, force: true)
    }

    private func handleQuery(_ text: String, force: Bool = false) {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Below threshold: reset state (hide label and placeholder)
        guard q.count >= 3 else {
            lastIssuedQuery = nil
            movies = []
            resultsCount = 0
            showResultsLabel = false
            showEmptyPlaceholder = false
            return
        }

        // De-duplicate identical queries (unless forced by Return key)
        if !force, q == lastIssuedQuery { return }
        lastIssuedQuery = q

        guard NetworkMonitor.shared.isConnected else {
            print("No Internet Connection")
            alertSubject.send(.noInternet)
            return
        }

        service.searchMovies(query: q, page: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.movies = response.results
                    self.updateUI()
                case .failure(let err):
                    print("Search error: \(type(of: err)) - \(err.localizedDescription)")
                    self.movies = []
                    self.updateUI()
                    self.alertSubject.send(.error(err.localizedDescription))
                }
            }
        }
    }

    private func updateUI() {
        resultsCount = movies.count
        showResultsLabel = true
        showEmptyPlaceholder = movies.isEmpty
    }
}
