//
//  String + Extension.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 11.12.2022.
//

import Foundation

extension String {
    func convertToDateFormate(current: String, convertTo: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = current
        dateFormatter.locale = Locale(identifier: "ru_RU")
        guard let date = dateFormatter.date(from: self) else {
            return self
        }
        dateFormatter.dateFormat = convertTo
        return dateFormatter.string(from: date)
    }
}
