//
//  NewsFeedViewModel.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import UIKit
import Combine
import WebKit

class NewsFeedViewModel {
    
//    ивенты приходящие с вью
    enum Input {
        case viewDidAppear
        case loadMoreNews
        case loadImage(fromUrlString: String)
        case pulledToRefresh
    }
    
//    ивенты поступающие во вью
    enum Output {
        case fetchNewsFeedDidFail(error: Error)
        case fetchNewsFeedDidSucceed
        case fetchImageDidFail(error: Error)
        case fetchImageDidSucceed(image: UIImage)
    }
    
    
    private let autodocAPIService: AutodocAPIServiceType
//    кастомный кеш изображений для улучшения произсодительности
    private let imageCache: ImageCacheType
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    var pageToLoad = 1
    var news = [News]()
    
    init(autodocAPIServiceType: AutodocAPIServiceType = AutodocAPIService(),
         imageCache: ImageCacheType = ImageCache()) {
        self.autodocAPIService = autodocAPIServiceType
        self.imageCache = imageCache
    }
    
//    MARK: - Слушаем события с вью
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [ weak self ] event in
            guard let self else { return }
            switch event {
            case .viewDidAppear, .loadMoreNews:
                self.handleNewsFeed()
            case .pulledToRefresh:
                self.pageToLoad = 1
                self.news = []
                self.imageCache.removeAllImages()
                self.handleNewsFeed()
            case .loadImage(let urlString):
                self.handleImage(from: urlString)
            }
        }.store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
//    MARK: - Ловим страницу новостей
    func handleNewsFeed() {
        autodocAPIService.newsFeedPublisher(from: self.pageToLoad)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.output.send(.fetchNewsFeedDidFail(error: error))
                }
            } receiveValue: { [ weak self ] news in
                guard let self else { return }
                self.pageToLoad += 2
                self.news += self.transformDate(in: news)
                self.output.send(.fetchNewsFeedDidSucceed)
            }.store(in: &cancellables)
    }
    
//    MARK: - Ловим изображение из кеша/сети
    func handleImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        autodocAPIService.imagePublisher(url: url).sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.output.send(.fetchNewsFeedDidFail(error: error))
            }
        } receiveValue: { [weak self] image in
            self?.output.send(.fetchImageDidSucceed(image: image))
        }.store(in: &cancellables)
    }
    
//    трансформирует дату из json в строку для View
    func transformDate(in allNews: [News]) -> [News] {
        var result = allNews
        
        for (index, _) in allNews.enumerated() {
            result[index].publishedDate = allNews[index].publishedDate.convertToDateFormate(current: "yyyy-MM-dd'T'HH:mm:ss", convertTo: "d MMMM")
        }
        return result
    }
}

