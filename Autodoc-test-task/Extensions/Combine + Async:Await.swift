//
//  Combine + Async:Await.swift
//  Autodoc-test-task
//
//  Created by Vasily Maslov on 02.12.2022.
//

import Foundation
import Combine

extension Future where Failure == Error {
//    паблишер future поддерживающий работу с паттерном async/await
    convenience init(asyncFunc: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
