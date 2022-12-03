//
//  NewsFeedModel.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 03.12.2022.
//

import Foundation

struct NewsFeedModel: Decodable {
    let news: [News]
    let totalCount: Int
}

struct News: Decodable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: String
    let url: String
    let fullUrl: String
    let titleImageUrl: String
    let categoryType: String
    
    
}
