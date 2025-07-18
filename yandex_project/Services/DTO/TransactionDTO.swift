//
//  TransactionDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
import Foundation

public struct TransactionDTO: Codable {
    public let id: Int
    public let accountId: Int
    public let categoryId: Int
    public let amount: String
    public let comment: String
    public let transactionDate: String
    public let createdAt: String
    public let updatedAt: String
}
extension TransactionDTO {
    func toDomain() -> Transaction {
        let decimalAmount = Decimal(string: amount) ?? .zero

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return Transaction(
            id:  id,
            accountId: accountId,
            categoryId: categoryId,
            amount: decimalAmount,
            comment: comment,
            transactionDate: iso.date(from: transactionDate) ?? Date(),
            createdAt: iso.date(from: createdAt) ?? Date(),
            updatedAt: iso.date(from: updatedAt) ?? Date()
        )
    }
    static func fromDomain(_ t: Transaction) -> TransactionDTO {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return TransactionDTO(
            id: t.id,
            accountId: t.accountId,
            categoryId: t.categoryId,
            amount: NSDecimalNumber(decimal: t.amount).stringValue,
            comment: t.comment,
            transactionDate: iso.string(from: t.transactionDate),
            createdAt: iso.string(from: t.createdAt),
            updatedAt: iso.string(from: t.updatedAt)
        )
    }
}
