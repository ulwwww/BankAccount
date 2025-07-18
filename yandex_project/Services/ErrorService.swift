//
//  ErrorService.swift
//  yandex_project
//
//  Created by ulwww on 12.06.25.
//
import Foundation
enum ErrorService: LocalizedError {
    case notFoundAllAccount
    case accountNotFound(id: Int)
    case transactionNotFound(id: Int)
    case emptyListTransaction
    case invalidDateRange
    var errorDescription: String? {
        switch self {
        case .notFoundAllAccount:
            return "there is not a single bank account"
        case .accountNotFound(let id):
            return "bank account identifier \(id) not found"
        case .transactionNotFound(let id):
            return "transaction identifier \(id) not found"
        case .emptyListTransaction:
            return "empty list of transactions"
        case .invalidDateRange:
            return "invalid date range"
        }
    }
}

public enum HTTPError: Error {
    case invalidURL
    case httpError(statusCode: Int, data: Data?)
    case encodingError(Error)
    case decodingError(Error)
    case transportError(Error)
    case invalidResponse
}
