//
//  UIImage + Extension.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 04.12.2022.
//

import UIKit

extension UIImage {
    //    функция возвращает отрендеренную и распакованную версию изображения. Запись этого изображения в кеш и использование его при отрисовке улучшит производительность ценой  пространства в хранилище
    func decodedImage() -> UIImage {
        guard let cgImage else { return self }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: cgImage.bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage)
    }
    
//    функция возвращает занимаемое изображением количество байтов
    func diskSize() -> Int {
        guard let data = self.jpegData(compressionQuality: 1) else { return 0 }
        let imageDataSize = NSData(data: data)
        let imageSize = imageDataSize.count
        return imageSize
    }
    
//    функция возвращает ресайзнутое изображение с сохранением соотношения сторон
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
//        вычисляет новый размер изображения с сохранением соотношения сторон
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
//        отрисовывает и возвращает новое изображение
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
