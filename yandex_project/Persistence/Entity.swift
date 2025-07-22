//
//  Untitled.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//
import SwiftData
import Foundation

enum OperationType: String, Codable {
    case add, update, delete
}

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var isIncome: Bool
    
    init(from domain: Category) {
        self.id = domain.id
        self.name = domain.name
        self.emoji = String(domain.emoji)
        self.isIncome = domain.isIncome == .income
    }
    
    func toCategory() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "?",
            isIncome: isIncome ? .income : .outcome
        )
    }
}

@Model
final class BankAccountEntity {
    @Attribute(.unique) var id: Int
    var userId: Int?
    var name: String
    var balance: String
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
    init(from domain: BankAccount) {
        self.id = domain.id
        self.userId = domain.userId
        self.name = domain.name
        self.balance = "\(domain.balance)"
        self.currency = domain.currency
        self.createdAt = domain.createdAt
        self.updatedAt = domain.updatedAt
    }
    
    func toBankAccount() -> BankAccount {
        BankAccount(
            id: id,
            userId: userId!,
            name: name,
            balance: Decimal(string: balance) ?? 0,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: Int
    var account: Int
    var category: Int
    var amount: Decimal
    var comment: String?
    var transactionDate: Date
    var createdAt: Date
    var updatedAt: Date

    init(from domain: Transaction) {
        self.id = domain.id
        self.account = domain.accountId
        self.category = domain.categoryId
        self.amount = domain.amount
        self.comment = domain.comment
        self.transactionDate = domain.transactionDate
        self.createdAt = domain.createdAt
        self.updatedAt = domain.updatedAt
    }

    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            accountId: account,
            categoryId: category,
            amount: amount,
            comment: comment ?? "",
            transactionDate: transactionDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class BackupOperationEntity {
    @Attribute(.unique) var id: Int
    var type: OperationType
    var payloadData: Data?
    var payloadTransactionId: Int
    var createdAt: Date
    init(id: Int, type: OperationType, payloadData: Data?, payloadTransactionId: Int) {
        self.id = id
        self.type = type
        self.payloadData = payloadData
        self.payloadTransactionId = payloadTransactionId
        self.createdAt = Date()
    }
}
