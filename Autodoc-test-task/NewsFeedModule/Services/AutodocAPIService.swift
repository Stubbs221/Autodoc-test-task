//
//  AutodocAPIService.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 04.12.2022.
//

import UIKit
import Combine

protocol AutodocAPIServiceType {
    var newsFeedUrlString: String { get set }
    
    func getNewsFeed(from page: Int) async throws -> [News]
    func getImageFrom(url: URL) async throws -> UIImage

    func newsFeedPublisher(from page: Int) -> Future<[News], Error>
    func imagePublisher(url: URL) -> Future<UIImage, Error>
}

class AutodocAPIService: AutodocAPIServiceType {
    
    private let imageCache = ImageCache()
    
    var newsFeedUrlString: String = "https://webapi.autodoc.ru/api/news/"
    
    func newsFeedPublisher(from page: Int) -> Future<[News], Error> {
        Future {
            try await self.getNewsFeed(from: page)
        }
    }
    
    func imagePublisher(url: URL) -> Future<UIImage, Error> {
        Future {
            try await self.getImageFrom(url: url)
        }
    }
    
//  MARK: - Запросы в сеть на async/await + Combine
    func getNewsFeed(from page: Int = 1) async throws -> [News] {
        guard let url = URL(string: newsFeedUrlString + String(page) + "/15") else { throw NetworkError.invalidURL }
        print(url)
        let (data, _) = try await URLSession.shared.data(from: url)
        let apiResult = try JSONDecoder().decode(NewsFeedModel.self, from: data)
        return apiResult.news
        
    }
    
    func getImageFrom(url: URL) async throws -> UIImage {
//        если изображение уже было загружено - возвращаем его из кеша по url
        if let image = imageCache[url] {
            return image
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw NetworkError.unableToDecodeData }
        self.imageCache[url] = image
        return image
    }
}

enum NetworkError: Error {
    case invalidURL
    case connectionFailed
    case unableToDecodeData
}

