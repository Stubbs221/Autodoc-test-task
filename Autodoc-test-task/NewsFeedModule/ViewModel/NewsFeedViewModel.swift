//
//  NewsFeedViewModel.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import UIKit
import Combine

class NewsFeedViewModel {
    
    enum Input {
        case viewDidAppear
        case loadMoreNews
        case loadImage(fromUrlString: String, withId: Int )
    }
    
    enum Output {
        case fetchNewsFeedDidFail(error: Error)
        case fetchNewsFeedDidSucceed
        case fetchImageDidFail(error: Error)
        case fetchImageDidSucceed(image: UIImage)
        
    }
    
    init(autodocAPIServiceType: AutodocAPIServiceType = AutodocAPIService()) {
        self.autodocAPIServiceType = autodocAPIServiceType
    }
    
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private let autodocAPIServiceType: AutodocAPIServiceType
    private var cancellables = Set<AnyCancellable>()
    var pageToLoad = 1
    var news = [News]()
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [ weak self ] event in
            switch event {
            case .viewDidAppear, .loadMoreNews:
                self?.handleNewsFeed()
            case .loadImage(let urlString, let id):
                self?.handleImage(from: urlString, with: id)
            }
        }.store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    func handleNewsFeed() {
        autodocAPIServiceType.newsFeedPublisher(from: self.pageToLoad).sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.output.send(.fetchNewsFeedDidFail(error: error))
            }
        } receiveValue: { [ weak self ] news in
            self?.pageToLoad += 2
            self?.news += news
            self?.output.send(.fetchNewsFeedDidSucceed)
        }.store(in: &cancellables)
    }
    
    func handleImage(from urlString: String, with id: Int) {
        guard let url = URL(string: urlString) else { return }
        autodocAPIServiceType.imagePublisher(url: url).sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.output.send(.fetchNewsFeedDidFail(error: error))
            }
        } receiveValue: { [weak self] image in
            self?.output.send(.fetchImageDidSucceed(image: image))
        }.store(in: &cancellables)

    }
}

