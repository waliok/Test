//
//  MovieDetailsviewController.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import SwiftUI

final class MovieDetailsHostingController: UIHostingController<MovieDetailsView> {
    private let viewModel: DetailsScreenViewModel
    
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
        rootView = MovieDetailsView(viewModel: viewModel) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.backgroundColor = .bg
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
