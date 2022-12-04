//
//  ImageCache.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 04.12.2022.
//

import UIKit

protocol ImageCacheType: AnyObject {
    func image(for url: URL) -> UIImage?
    
    func insertImage(_ image: UIImage?, for url: URL)
    
    func removeImage(for url: URL)
    
    func removeAllImages()
    
//    доступ к картинке по ключу(как к элементу массива) для последующих crud операций через точку
    subscript(_ url: URL) -> UIImage? { get set }
    
}

final class ImageCache: ImageCacheType {
    
    
//    кэш первого уровня для изображений
    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    
//    кэш второго уровня для декодированных изображений
    private lazy var decodedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
        
//        print(cache.totalCostLimit)
        return cache
    }()
    
    private let config: Config
    
    struct Config {
        let countLimit: Int
        let memoryLimit: Int
//        дефолтный конфиг на 100 элементов(изображений) общего размера 100мб
        static let defaultConfig = Config(countLimit: 100, memoryLimit: 1024 * 1024 * 200)
    }
    
    init(config: Config = Config.defaultConfig) {
        self.config = config
    }
    
    subscript(url: URL) -> UIImage? {
        get {
            return image(for: url)
        }
        set {
            return insertImage(newValue, for: url)
        }
    }
    
    func image(for url: URL) -> UIImage? {
//        если есть decoded версия - возвращает ее
        if let decodedImage = decodedImageCache.object(forKey: url as AnyObject) as? UIImage {
            return decodedImage
        }
//        если нет - ищет обычное изображение и также возвращает decoded версию
        if let image = imageCache.object(forKey: url as AnyObject) as? UIImage {
            let compressedImage = image.scalePreservingAspectRatio(targetSize: CGSize(width: UIScreen.main.bounds.width, height: 200))
            let decodedImage = compressedImage.decodedImage()
            decodedImageCache.setObject(decodedImage as AnyObject, forKey: url as AnyObject, cost: decodedImage.diskSize())
            
            return decodedImage
        }
       
        return nil
    }
    
    func insertImage(_ image: UIImage?, for url: URL) {
        guard let image else { return removeImage(for: url) }
        let compressedImage = image.scalePreservingAspectRatio(targetSize: CGSize(width: UIScreen.main.bounds.width / 2, height: 100))
        let decodedImage = compressedImage.decodedImage()
        print(decodedImage.diskSize())

        imageCache.setObject(compressedImage, forKey: url as AnyObject)
        decodedImageCache.setObject(decodedImage as AnyObject, forKey: url as AnyObject, cost: decodedImage.diskSize())
        
    }
    
    func removeImage(for url: URL) {
        imageCache.removeObject(forKey: url as AnyObject)
        decodedImageCache.removeObject(forKey: url as AnyObject)
    }
    
    func removeAllImages() {
        imageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
    }
}
