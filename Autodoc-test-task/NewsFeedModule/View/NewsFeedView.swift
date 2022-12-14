//
//  ViewController.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import UIKit
import Combine
import SafariServices

class NewsFeedView: UIViewController {
    
    //    свойства и тайпэлиасы Diffable Data Source
    typealias DataSource = UICollectionViewDiffableDataSource<String?, News>
    typealias Snapshot = NSDiffableDataSourceSnapshot<String?, News>
    private var dataSource: DataSource?
    
    
    private var isLoading = false
    //    футер
    private var loadingView: LoadingReusableView?
    //    рефреш контрол для пуд ту рефреш
    private let refreshControl = UIRefreshControl()
    private var selectedItems: Set<Int> = []
    
    
    //    свойства Combine
    private let viewModel = NewsFeedViewModel()
    private var input: PassthroughSubject<NewsFeedViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        setupDataSource()
        setupFooter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }
    
//    обновляем лейаут коллекции при смене ориентации на iPad
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.newsFeedCollectionView.collectionViewLayout.invalidateLayout()
        guard let dataSource else { return }
        var snapshot = dataSource.snapshot()
                    snapshot.reloadSections([""])
        self.dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private lazy var newsFeedCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(NewsFeedCell.self, forCellWithReuseIdentifier: NewsFeedCell.reuseIdentifier)
        collectionView.register(LoadingReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingReusableView.reuseIdentifier)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        collectionView.refreshControl?.addTarget(self, action: #selector(callPullToRefresh), for: .valueChanged)
        return collectionView
    }()
    
    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(newsFeedCollectionView)
        
        NSLayoutConstraint.activate([
            newsFeedCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newsFeedCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newsFeedCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            newsFeedCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    @objc func callPullToRefresh() {
        self.selectedItems.removeAll()
        input.send(.pulledToRefresh)
    }
    
//    MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(
                UIScreen.main.bounds.width > 400 ? 0.5 : 1
            ),
            heightDimension: .estimated(UIScreen.main.bounds.height / 3 ))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: itemSize.heightDimension)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count:
                UIScreen.main.bounds.width > 400 ? 2 : 1
        )
        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
//    MARK: - Биндинг Combine
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .fetchNewsFeedDidSucceed:
                    self.refreshControl.endRefreshing()
                    self.updateCollectionView(news: self.viewModel.news)
                    print(self.viewModel.pageToLoad)
                case .fetchNewsFeedDidFail(let error):
                    print(error.localizedDescription)
                default: break
                }
            }.store(in: &cancellables)
    }
}

extension NewsFeedView: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingReusableView.reuseIdentifier, for: indexPath) as? LoadingReusableView else { return UICollectionReusableView() }
            loadingView = footerView
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
            input.send(.loadMoreNews)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentNews = self.dataSource?.itemIdentifier(for: indexPath) else { return }
        
//        проверяем есть ли выделенная ячейка в сете выделенных ячеек
        if selectedItems.contains(currentNews.id) {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        selectedItems.insert(currentNews.id)
        
        guard let dataSource else { return }
        var snapshot = dataSource.snapshot()
        
        snapshot.reloadItems([currentNews])
        self.dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

//      MARK: - метод открытия SafariViewController
extension NewsFeedView {
    func openWebView(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}

//      MARK: - Методы Diffable Data Source
extension NewsFeedView {
    
    
    func setupFooter() {
        dataSource?.supplementaryViewProvider = { (
            collectionView: UICollectionView,
            kind: String,
            indexPath: IndexPath) -> UICollectionReusableView? in
            
            guard let footer: LoadingReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingReusableView.reuseIdentifier, for: indexPath) as? LoadingReusableView else { return UICollectionReusableView() }
            return footer
        }
    }
    
    func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: newsFeedCollectionView, cellProvider: { (collectionView, indexPath, news) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsFeedCell.reuseIdentifier, for: indexPath) as? NewsFeedCell else { return UICollectionViewCell() }
            
            if self.selectedItems.contains(news.id) {
                cell.isCellPressed = true
            }
            cell.configure(news: news, parentView: self)
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



