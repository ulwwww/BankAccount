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
final class TransactionEntity {
    @Attribute(.unique) var id: Int
    @Attribute var accountId: Int
    @Attribute var categoryId: Int
    @Attribute var amount: Decimal
    @Attribute var comment: String
    @Attribute var transactionDate: Date
    @Attribute var createdAt: Date
    @Attribute var updatedAt: Date

    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, comment: String, transactionDate: Date, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.comment = comment
        self.transactionDate = transactionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class BackupOperationEntity {
    @Attribute(.unique) var id: Int
    @Attribute var type: OperationType
    @Attribute var payload: Data?
    @Attribute var payloadTransactionId: Int?

    init(id: Int, type: OperationType, payload: Data?, payloadTransactionId: Int?) {
        self.id = id
        self.type = type
        self.payload = payload
        self.payloadTransactionId = payloadTransactionId
    }
}

@Model
final class BankAccountEntity {
    @Attribute(.unique) var id: Int
    @Attribute var userId: Int
    @Attribute var name: String
    @Attribute var balance: Decimal
    @Attribute var currency: String
    @Attribute var createdAt: Date?
    @Attribute var updatedAt: Date?

    init(id: Int, userId: Int, name: String, balance: Decimal, currency: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class BackupAccountOperationEntity {
    @Attribute(.unique) var id: Int
    @Attribute var type: OperationType
    @Attribute var payloadAccountId: Int

    init(id: Int, type: OperationType, payloadAccountId: Int) {
        self.id = id
        self.type = type
        self.payloadAccountId = payloadAccountId
    }
}

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: Int
    @Attribute var name: String
    @Attribute var emoji: String
    @Attribute var isIncome: Bool

    init(id: Int, name: String, emoji: String, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }
}

extension TransactionEntity {
    convenience init(from domain: Transaction) {
        self.init(
            id: domain.id,
            accountId: domain.accountId,
            categoryId: domain.categoryId,
            amount: domain.amount,
            comment: domain.comment,
            transactionDate: domain.transactionDate,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
    func update(from domain: Transaction) {
        accountId = domain.accountId
        categoryId = domain.categoryId
        amount = domain.amount
        comment = domain.comment
        transactionDate = domain.transactionDate
        updatedAt = domain.updatedAt
    }
    func toDomain() -> Transaction {
        Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            comment: comment,
            transactionDate: transactionDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension BankAccountEntity {
    convenience init(from domain: BankAccount) {
        self.init(
            id: domain.id,
            userId: domain.userId,
            name: domain.name,
            balance: domain.balance,
            currency: domain.currency,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
    func update(from domain: BankAccount) {
        name = domain.name
        balance = domain.balance
        updatedAt = domain.updatedAt
    }
    func toDomain() -> BankAccount {
        BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension CategoryEntity {
    convenience init(from domain: Category) {
        self.init(
            id: domain.id,
            name: domain.name,
            emoji: String(domain.emoji),
            isIncome: domain.isIncome == .income
        )
    }
    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            emoji: Character(emoji),
            isIncome: isIncome ? .income : .outcome
        )
    }
}
