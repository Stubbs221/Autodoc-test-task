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
    
    enum Input {
        case viewDidAppear
        case loadMoreNews
        case loadImage(fromUrlString: String)
        case pulledToRefresh
        case openFullNewsButtonPressed(fromUrlString: String)
    }
    
    enum Output {
        case fetchNewsFeedDidFail(error: Error)
        case fetchNewsFeedDidSucceed
        case fetchImageDidFail(error: Error)
        case fetchImageDidSucceed(image: UIImage)
        case updateWithChangedData
        case openWebView(fromUrl: URL)
    }
    
    init(autodocAPIServiceType: AutodocAPIServiceType = AutodocAPIService(),
         imageCache: ImageCacheType = ImageCache()) {
        self.autodocAPIService = autodocAPIServiceType
        self.imageCache = imageCache
    }
    
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private let autodocAPIService: AutodocAPIServiceType
    private let imageCache: ImageCacheType
    private var cancellables = Set<AnyCancellable>()
    var pageToLoad = 1
    var news = [News]()
    
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
            case .openFullNewsButtonPressed(let fullUrlString):
                guard let url = URL(string: fullUrlString) else { return }
                self.output.send(.openWebView(fromUrl: url))
//                self.handeOpenWebViewRequest(with: fullUrlString)
            }
        }.store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
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
        let months = ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"]
        
        var result = allNews
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        for (index, _) in allNews.enumerated() {
            guard let date = dateFormatter.date(from: result[index].publishedDate) else { continue }
            if Calendar.current.isDateInToday( date ) {
                result[index].publishedDate = "сегодня"
            } else {
                let month = months[(Int(result[index].publishedDate.prefix(7).suffix(2)) ?? 0) - 1]
                var day = String(result[index].publishedDate.prefix(10).suffix(2))
                if day.first == "0" {
                    day = String(day.suffix(1))
                }
                result[index].publishedDate = day + " " + month
            }
        }
        return result
    }
    

    
}

