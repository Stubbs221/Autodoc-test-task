//
//  ViewController.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import UIKit
import Combine


class NewsFeedView: UIViewController {

//    проперти Diffable Data Source
    typealias DataSource = UICollectionViewDiffableDataSource<String?, News>
    typealias Snapshot = NSDiffableDataSourceSnapshot<String?, News>
    private var dataSource: DataSource?
    
    
    private var isLoading = false
    private var loadingView: LoadingReusableView?
    
//    проперти Combine
    private let viewModel = NewsFeedViewModel()
    private var input: PassthroughSubject<NewsFeedViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(newsFeedCollectionView)
        bind()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }
    
    private lazy var newsFeedCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(NewsFeedCell.self, forCellWithReuseIdentifier: NewsFeedCell.reuseIdentifier)
        collectionView.register(LoadingReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingReusableView.reuseIdentifier)
        collectionView.frame = self.view.bounds
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        return collectionView

    }()
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.8),
            heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(isLoading ? 0.0 : 55))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
        section.boundarySupplementaryItems = [footer]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .fetchNewsFeedDidSucceed:
                    self.updateCollectionView(news: self.viewModel.news)
//                    print(newsFeed)
                    print(self.viewModel.pageToLoad)
                case .fetchNewsFeedDidFail(let error):
                    print(error.localizedDescription)
                case .fetchImageDidSucceed(let image):
                    print("image")
                case .fetchImageDidFail(let error):
                    print(error)
                }
            }.store(in: &cancellables)
        
        setupDataSource()
        setupFooter()
    }
    
    
}

extension NewsFeedView: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingReusableView.reuseIdentifier, for: indexPath) as? LoadingReusableView else { return UICollectionReusableView() }
            loadingView = footerView
            loadingView?.backgroundColor = .clear
            return footerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.startAnimating()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.stopAnimating()
        }
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == viewModel.news.count - 1  && !self.isLoading {
            loadMoreData()
        }
        
        func loadMoreData() {
            input.send(.loadMoreNews)
        }
    }
    
    
}


extension NewsFeedView {
    
    func setupFooter() {
        dataSource?.supplementaryViewProvider = { (
            collectionView: UICollectionView,
            kind: String,
            indexPath: IndexPath) -> UICollectionReusableView? in
            
            guard let footer: LoadingReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingReusableView.reuseIdentifier, for: indexPath) as? LoadingReusableView else { return UICollectionReusableView() }
//            footer.backgroundColor = .red
            
            return footer
            
        }
        
        
    }
    
    
    func setupDataSource() {
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: newsFeedCollectionView, cellProvider: { (collectionView, indexPath, itemIdentifier) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsFeedCell.reuseIdentifier, for: indexPath) as? NewsFeedCell else { return UICollectionViewCell() }
            
            cell.configure(with: itemIdentifier)
//            input.send(.loadImage(fromUrlString: itemIdentifier.titleImageUrl, withId: itemIdentifier.id))
//            cell.titleImageView =
            return cell
        })
    }
    
    func updateCollectionView(news: [News]) {
        var snapshot = Snapshot()
        snapshot.appendSections([""])
        snapshot.appendItems(news, toSection: "")
        dataSource?.apply(snapshot, animatingDifferences: true)
        
    }
}



