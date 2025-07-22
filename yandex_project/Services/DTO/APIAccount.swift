//
//  APIAccount.swift
//  yandex_project
//
//  Created by ulwww on 21.07.25.
//
import Foundation


struct APITransactionResponse: Decodable {
    let id: Int
    let account: APIAccount
    let category: APICategory
    let amount: String
    let transactionDate: String
    let comment: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, account, category, amount
        case transactionDate, comment, createdAt, updatedAt
    }
    var parsedTransactionDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: transactionDate) ?? Date()
    }

    var parsedCreatedAt: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: createdAt) ?? Date()
    }

    var parsedUpdatedAt: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: updatedAt) ?? Date()
    }
}

struct APIAccount: Decodable {
    let id: Int
    let name: String
    let balance: String
    let currency: String

    enum CodingKeys: String, CodingKey {
        case id, name, balance, currency
    }
}

struct APICategory: Decodable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}


