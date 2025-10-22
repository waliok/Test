//
//  MovieDetailsviewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import SwiftUI
import Combine

final class MovieDetailsHostingController: UIHostingController<MovieDetailsView> {
    private let viewModel: DetailsScreenViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: DetailsScreenViewModel) {
        self.viewModel = viewModel
        let rootView = MovieDetailsView(viewModel: viewModel, onBack: nil)
        super.init(rootView: rootView)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                guard let self = self else { return }
                switch alert {
                case .noInternet:
                    // Show an alert with Retry action
                    let retry = UIAlertAction(title: "Retry", style: .default) { _ in
                        self.viewModel.fetch()
                    }
                    let cancel = UIAlertAction.cancel
                    self.showAlertWithActions(title: "No Internet", message: "Please check your connection and try again.", actions: [retry, cancel])
                case .error(let message):
                    self.showError(message: message)
                }
            }
            .store(in: &cancellables)
        rootView = MovieDetailsView(viewModel: viewModel) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
