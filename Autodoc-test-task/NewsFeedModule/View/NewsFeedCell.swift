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
    
    private var cancellable = Set<AnyCancellable>()
    private var input: PassthroughSubject<NewsFeedViewModel.Input, Never> = .init()
    private var viewModel = NewsFeedViewModel()
    private var fullURLString = ""

    
    var isCellPressed: Bool = false
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var desctiprionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()
    
    lazy var publishedDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray2
        return label
    }()
    
    lazy var categoryTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var titleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    var openFullNewsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Подробнее", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.isUserInteractionEnabled = true
        button.isEnabled = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .fetchImageDidSucceed(let image):
                    self.titleImageView.image = image
                case .fetchImageDidFail(let error):
                    print(error.localizedDescription)
                    self.titleImageView.image = UIImage(named: "placeholder")
                default:
                    break
                
                }
            }.store(in: &cancellable)
        
        
    }
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        if self.isCellPressed {
            layoutAttributes.bounds.size.height = titleLabel.bounds.height +
            desctiprionLabel.bounds.height +
            publishedDateLabel.bounds.height +
            categoryTypeLabel.bounds.height +
            openFullNewsButton.bounds.height +
            UIScreen.main.bounds.height / 4 + 30
        } else {
            layoutAttributes.bounds.size.height = titleLabel.bounds.height +
            UIScreen.main.bounds.height / 4 + 30
        }
        
        
        
        return layoutAttributes
    }
    
    func setupUI() {
        
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(desctiprionLabel)
        contentView.addSubview(publishedDateLabel)
        contentView.addSubview(categoryTypeLabel)
        contentView.addSubview(titleImageView)
        addSubview(openFullNewsButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25)])
        
        NSLayoutConstraint.activate([
            desctiprionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            desctiprionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            desctiprionLabel.topAnchor.constraint(equalTo: publishedDateLabel.bottomAnchor, constant: 0),])
        
        NSLayoutConstraint.activate([
            publishedDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            publishedDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            publishedDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0)])
        
        NSLayoutConstraint.activate([
            categoryTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categoryTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categoryTypeLabel.topAnchor.constraint(equalTo: titleImageView.bottomAnchor, constant: 0)])
        
        NSLayoutConstraint.activate([
            titleImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height / 4 ),
            titleImageView.widthAnchor.constraint(equalToConstant: contentView.bounds.width - 40),
            titleImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)])
        
        NSLayoutConstraint.activate([
            openFullNewsButton.heightAnchor.constraint(equalToConstant: 20),
            openFullNewsButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            openFullNewsButton.topAnchor.constraint(equalTo: desctiprionLabel.bottomAnchor)
            ])
        
        
        let openConstraint = titleImageView.topAnchor.constraint(equalTo: desctiprionLabel.bottomAnchor, constant: 25)

        let closeConstraint = titleImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5)

        if self.isCellPressed {
            desctiprionLabel.isHidden = false
            publishedDateLabel.isHidden = false
            categoryTypeLabel.isHidden = false
            openFullNewsButton.isHidden = false
            openConstraint.isActive = true
            closeConstraint.isActive = false
            
        } else {
            desctiprionLabel.isHidden = true
            publishedDateLabel.isHidden = true
            categoryTypeLabel.isHidden = true
            openFullNewsButton.isHidden = true
            openConstraint.isActive = false
            closeConstraint.isActive = true

        }
    }
    
    @objc func openFullNewsButtonPressed(_ sender: UIButton) {
        input.send(.openFullNewsButtonPressed(fromUrlString: fullURLString))
    }
    
    func configure(news: News) {
        self.titleLabel.text = news.title
        self.desctiprionLabel.text = news.description
        self.publishedDateLabel.text = news.publishedDate
        self.categoryTypeLabel.text = news.categoryType
        self.fullURLString = news.fullUrl
        self.openFullNewsButton.addTarget(self, action: #selector(openFullNewsButtonPressed(_:)), for: .touchUpInside)

        loadImage(for: news)
        setupUI()
    }
    
    private func loadImage(for news: News) {
        input.send(.loadImage(fromUrlString: news.titleImageUrl))
    }
    
    override func prepareForReuse() {
        self.titleImageView.image = nil
        self.titleLabel.text = nil
        self.desctiprionLabel.text = nil
        self.publishedDateLabel.text = nil
        self.categoryTypeLabel.text = nil
        self.isCellPressed = false
        titleLabel.removeFromSuperview()
    }
}
