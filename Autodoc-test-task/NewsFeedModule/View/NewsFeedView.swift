//
//  ViewController.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import UIKit
import Combine

class NewsFeedView: UIViewController {

    private let viewModel = NewsFeedViewModel()
    private var input: PassthroughSubject<NewsFeedViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }

    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .fetchNewsFeedDidSucceed(let newsFeed):
                    print(newsFeed)
                    print(self?.viewModel.pageToLoad)
                case .fetchNewsFeedDidFail(let error):
                    print(error.localizedDescription)
                }
            }.store(in: &cancellables)
    }
}

