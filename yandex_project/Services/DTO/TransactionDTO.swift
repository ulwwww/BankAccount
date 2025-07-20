//
//  TransactionDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
import Foundation

struct TransactionDTO: Codable {
    public let id: Int
    public let account: AccountStateDTO
    public let category: CategoryDTO
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
            accountId: account.id,
            categoryId: category.id,
            amount: Decimal(string: amount) ?? .zero,
            comment: comment,
            transactionDate: iso.date(from: transactionDate) ?? Date(),
            createdAt: iso.date(from: createdAt) ?? Date(),
            updatedAt: iso.date(from: updatedAt) ?? Date()
        )
    }
    static func fromDomain(_ t: Transaction) -> TransactionDTO {
        let iso = ISO8601DateFormatter()
        let account = AccountStateDTO(
            id: t.accountId,
            name: nil,
            balance: nil,
            currency: nil
        )
        let category = CategoryDTO(
            id: t.categoryId,
            name: "",
            emoji: "",
            isIncome: true
        )
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return TransactionDTO(
            id: t.id,
            account: account,
            category: category,
            amount: NSDecimalNumber(decimal: t.amount).stringValue,
            comment: t.comment,
            transactionDate: iso.string(from: t.transactionDate),
            createdAt: iso.string(from: t.createdAt),
            updatedAt: iso.string(from: t.updatedAt)
        )
    }
}
