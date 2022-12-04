//
//  NewsFeedCell.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 04.12.2022.
//

import UIKit
import Combine

class NewsFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "Cell"
    
    private var cancellable: AnyCancellable?
    
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var desctiprionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var publishedDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var categoryTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var titleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(desctiprionLabel)
        contentView.addSubview(publishedDateLabel)
        contentView.addSubview(categoryTypeLabel)
        contentView.addSubview(titleImageView)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)])
        
        NSLayoutConstraint.activate([
            titleImageView.heightAnchor.constraint(equalToConstant: 120),
            titleImageView.widthAnchor.constraint(equalToConstant: 120),
            titleImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with news: News) {
        
        self.titleLabel.text = news.title
        self.desctiprionLabel.text = news.description
        self.publishedDateLabel.text = news.publishedDate
        self.categoryTypeLabel.text = news.categoryType
        
        cancellable = loadImage(for: news).sink(receiveCompletion: { [ weak self ] completion in
            if case .failure( _) = completion {
                self?.showImage(image: UIImage(named: "placeholder"))
            }
        }, receiveValue: { [weak self] image in
            self?.showImage(image: image)
        })
    }
    
    private func loadImage(for news: News) -> Future<UIImage, Error> {
        guard let url = URL(string: news.titleImageUrl) else {
            return Future { $0(.failure(NetworkError.invalidURL ))}
        }
        return AutodocAPIService.shared.imagePublisher(url: url)
    }
    
    private func showImage(image: UIImage?) {
        DispatchQueue.main.async {
            self.titleImageView.image = image
        }
    }
    
    override func prepareForReuse() {
        self.titleImageView.image = nil
        self.titleLabel.text = nil
        self.desctiprionLabel.text = nil
        self.publishedDateLabel.text = nil
        self.categoryTypeLabel.text = nil
    }
}
