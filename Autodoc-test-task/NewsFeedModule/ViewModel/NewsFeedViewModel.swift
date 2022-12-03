//
//  NewsFeedViewModel.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import Foundation
import Combine

class NewsFeedViewModel {
    
    enum Input {
        case viewDidAppear
    }
    
    enum Output {
        case fetchNewsFeedDidFail(error: Error)
        case fetchNewsFeedDidSucceed(newsFeed: [News])
        
    }
    
    init(autodocAPIServiceType: AutodocAPIServiceType = AutodocAPIService()) {
        self.autodocAPIServiceType = autodocAPIServiceType
    }
    
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private let autodocAPIServiceType: AutodocAPIServiceType
    private var cancellables = Set<AnyCancellable>()
    var pageToLoad = 1
    private var news = [News]()
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [ weak self ] event in
            switch event {
            case .viewDidAppear:
                self?.handleNewsFeed()
            }
        }.store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    func handleNewsFeed() {
        autodocAPIServiceType.newsFeedPublisher(from: self.pageToLoad).sink { [ weak self ] completion in
            if case .failure(let error) = completion {
                self?.output.send(.fetchNewsFeedDidFail(error: error))
            }
        } receiveValue: { [ weak self ] news in
            self?.pageToLoad += 1
            self?.output.send(.fetchNewsFeedDidSucceed(newsFeed: news))
        }.store(in: &cancellables)
    }
}

protocol AutodocAPIServiceType {
    
    var newsFeedUrlString: String { get set }
    
    func getNewsFeed(from page: Int) async throws -> [News]
    
    func newsFeedPublisher(from page: Int) -> Future<[News], Error>
}

class AutodocAPIService: AutodocAPIServiceType {
    
    
    var newsFeedUrlString: String = "https://webapi.autodoc.ru/api/news/"
    
    func getNewsFeed(from page: Int) async throws -> [News] {
        guard let url = URL(string: newsFeedUrlString + String(page) + "/15") else { throw NetworkError.invalidURL }
        print(url)
        let (data, responce) = try await URLSession.shared.data(from: url)
        
        let apiResult = try JSONDecoder().decode(NewsFeedModel.self, from: data)
        return apiResult.news
        
    }
    
    func newsFeedPublisher(from page: Int) -> Future<[News], Error> {
        Future {
            try await self.getNewsFeed(from: page)
        }
    }
    
    func getNew
    
    
}

enum NetworkError: Error {
    case invalidURL
    case connectionFailed
    case unableToDecodeData
}
