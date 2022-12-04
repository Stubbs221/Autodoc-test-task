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
    
    func diskSize() -> Int {
        guard let data = self.jpegData(compressionQuality: 1) else { return 0 }
//                self.jpegData(compressionQuality: 1) else { return 0 }
        let imageDataSize = NSData(data: data)
        let imageSize = imageDataSize.count
        return imageSize
    }
}
