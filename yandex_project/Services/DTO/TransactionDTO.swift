//
//  TransactionDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
import Foundation

struct TransactionDTO: Codable {
    public let id: Int
    public let account: Int
    public let category: Int
    public let amount: String
    public let comment: String
    public let transactionDate: String
    public let createdAt: String
    public let updatedAt: String
}
extension TransactionDTO {
    func toDomain() -> Transaction {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Transaction(
            id:  id,
            accountId: account,
            categoryId: category,
            amount: Decimal(string: amount) ?? .zero,
            comment: comment,
            transactionDate: iso.date(from: transactionDate) ?? Date(),
            createdAt: iso.date(from: createdAt) ?? Date(),
            updatedAt: iso.date(from: updatedAt) ?? Date()
        )
    }
    static func fromDomain(_ t: Transaction) -> TransactionDTO {
        let iso = ISO8601DateFormatter()
        _ = CategoryDTO(
            id: t.categoryId,
            name: "",
            emoji: "",
            isIncome: true
        )
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return TransactionDTO(
            id: t.id,
            account: t.accountId,
            category: t.categoryId,
            amount: NSDecimalNumber(decimal: t.amount).stringValue,
            comment: t.comment,
            transactionDate: iso.string(from: t.transactionDate),
            createdAt: iso.string(from: t.createdAt),
            updatedAt: iso.string(from: t.updatedAt)
        )
    }
}

struct CreateTransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dateString = formatter.string(from: transactionDate)
        try container.encode(dateString, forKey: .transactionDate)
        try container.encode(comment, forKey: .comment)
    }
}
