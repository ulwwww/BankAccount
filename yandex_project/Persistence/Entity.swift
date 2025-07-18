//
//  Untitled.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//
import SwiftData
import Foundation

@Model
final class TransactionEntity {
    @Attribute(.unique) public var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var comment: String
    var transactionDate: Date
    var createdAt: Date
    var updatedAt: Date
    
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
    var type: OperationType
    var payload: Data

    init(id: Int, type: OperationType, payload: Data) {
        self.id = id
        self.type = type
        self.payload = payload
    }
}

@Model
final class BankAccountEntity {
    @Attribute(.unique) var id: Int
    var userId: Int
    var name: String
    var balance: Decimal
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
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
    var type: OperationType
    var payload: Data
    init(id: Int, type: OperationType, payload: Data) {
        self.id = id;
        self.type = type;
        self.payload = payload
    }
}

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var isIncome: Bool
    
    init(id: Int, name: String, emoji: String, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }
}

enum OperationType: String, Codable {
    case create, update, delete
}
