//
//  SwiftDataStorage.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//

import SwiftData
import Foundation

final class SwiftDataTransactionsStorage: TransactionsStorage {
    private let container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }
    @MainActor func fetchAll() throws -> [Transaction] {
        let entities = try container.mainContext.fetch(FetchDescriptor<TransactionEntity>())
        return entities.map { e in
            Transaction(id: e.id, accountId: e.accountId, categoryId: e.categoryId, amount: e.amount,
                        comment: e.comment, transactionDate: e.transactionDate,
                        createdAt: e.createdAt, updatedAt: e.updatedAt)
        }
    }
    @MainActor func create(_ transaction: Transaction) throws {
        let e = TransactionEntity(id: transaction.id, accountId: transaction.accountId,
                                  categoryId: transaction.categoryId, amount: transaction.amount,
                                  comment: transaction.comment, transactionDate: transaction.transactionDate,
                                  createdAt: transaction.createdAt, updatedAt: transaction.updatedAt)
        container.mainContext.insert(e)
        try container.mainContext.save()
    }
    @MainActor func update(_ transaction: Transaction) throws {
        let desc = FetchDescriptor<TransactionEntity>(predicate: #Predicate<TransactionEntity> { $0.id == transaction.id })
        guard let e = try container.mainContext.fetch(desc).first else {
            throw NSError(domain: "TransactionsStorage", code: 404, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"])
        }
        e.accountId = transaction.accountId; e.categoryId = transaction.categoryId;
        e.amount = transaction.amount; e.comment = transaction.comment;
        e.transactionDate = transaction.transactionDate; e.updatedAt = transaction.updatedAt
        try container.mainContext.save()
    }
    @MainActor func delete(id: Int) throws {
        let desc = FetchDescriptor<TransactionEntity>(predicate: #Predicate<TransactionEntity> { $0.id == id })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach { container.mainContext.delete($0) }
        try container.mainContext.save()
    }
}

final class SwiftDataTransactionsBackUpStorage: TransactionsBackUpStorage {
    private let container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }
    @MainActor func fetchAll() throws -> [BackupOperation] {
        let entities = try container.mainContext.fetch(FetchDescriptor<BackupOperationEntity>())
        return entities.map { e in
            BackupOperation(id: e.id, type: e.type, payload: e.payload)
        }
    }
    @MainActor func saveBackupOperation(_ op: BackupOperation) throws {
        let desc = FetchDescriptor<BackupOperationEntity>(predicate: #Predicate<BackupOperationEntity> { $0.id == op.id })
        if let existing = try container.mainContext.fetch(desc).first {
            existing.type = op.type
            existing.payload = op.payload
        } else {
            let e = BackupOperationEntity(id: op.id, type: op.type, payload: op.payload)
            container.mainContext.insert(e)
        }
        try container.mainContext.save()
    }
    @MainActor func clearSyncedOperations(ids: [Int]) throws {
        let desc = FetchDescriptor<BackupOperationEntity>(predicate: #Predicate<BackupOperationEntity> { ids.contains($0.id) })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach { container.mainContext.delete($0) }
        try container.mainContext.save()
    }
}

final class SwiftDataBankAccountsStorage: BankAccountsStorage {
    private let container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }
    @MainActor func fetchAll() throws -> [BankAccount] {
        let entities = try container.mainContext.fetch(FetchDescriptor<BankAccountEntity>())
        return entities.map { e in
            BankAccount(id: e.id, userId: e.userId, name: e.name, balance: e.balance, currency: e.currency, createdAt: e.createdAt, updatedAt: e.updatedAt)
        }
    }
    @MainActor func create(_ account: BankAccount) throws {
        let e = BankAccountEntity(id: account.id, userId: account.userId, name: account.name, balance: account.balance, currency: account.currency, createdAt: account.createdAt, updatedAt: account.updatedAt)
        container.mainContext.insert(e)
        try container.mainContext.save()
    }
    @MainActor func update(_ account: BankAccount) throws {
        let desc = FetchDescriptor<BankAccountEntity>(predicate: #Predicate<BankAccountEntity> { $0.id == account.id })
        guard let e = try container.mainContext.fetch(desc).first else {
            throw NSError(domain: "BankAccountsStorage", code: 404, userInfo: [NSLocalizedDescriptionKey: "Account not found"])
        }
        e.name = account.name; e.balance = account.balance; e.updatedAt = account.updatedAt
        try container.mainContext.save()
    }
    @MainActor func delete(id: Int) throws {
        let desc = FetchDescriptor<BankAccountEntity>(predicate: #Predicate<BankAccountEntity> { $0.id == id })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach { container.mainContext.delete($0) }
        try container.mainContext.save()
    }
}

final class SwiftDataBankAccountsBackUpStorage: BankAccountsBackUpStorage {
    private let container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }
    @MainActor func fetchAll() throws -> [BackupOperation] {
        let entities = try container.mainContext.fetch(FetchDescriptor<BackupAccountOperationEntity>())
        return entities.map { e in BackupOperation(id: e.id, type: e.type, payload: e.payload) }
    }
    @MainActor func saveBackupOperation(_ op: BackupOperation) throws {
        let desc = FetchDescriptor<BackupAccountOperationEntity>(predicate: #Predicate<BackupAccountOperationEntity> { $0.id == op.id })
        if let existing = try container.mainContext.fetch(desc).first {
            existing.type = op.type; existing.payload = op.payload
        } else {
            let e = BackupAccountOperationEntity(id: op.id, type: op.type, payload: op.payload)
            container.mainContext.insert(e)
        }
        try container.mainContext.save()
    }
    @MainActor func clearSyncedOperations(ids: [Int]) throws {
        let desc = FetchDescriptor<BackupAccountOperationEntity>(predicate: #Predicate<BackupAccountOperationEntity> { ids.contains($0.id) })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach { container.mainContext.delete($0) }
        try container.mainContext.save()
    }
}

final class SwiftDataCategoriesStorage: CategoriesStorage {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    func fetchAll() throws -> [Category] {
        let ents = try container.mainContext.fetch(FetchDescriptor<CategoryEntity>())
        let dtos: [CategoryDTO] = ents.map { e in
            CategoryDTO(
                id: e.id,
                name: e.name,
                emoji: e.emoji,
                isIncome: e.isIncome
            )
        }
        return dtos.map { $0.toDomain() }
    }

    @MainActor
    func saveAll(_ categories: [Category]) throws {
        let old = try container.mainContext.fetch(FetchDescriptor<CategoryEntity>())
        old.forEach { container.mainContext.delete($0) }

        for category in categories {
            let dto = CategoryDTO(
                id: category.id,
                name: category.name,
                emoji: String(category.emoji),
                isIncome: category.isIncome == .income
            )
            let e = CategoryEntity(
                id: dto.id,
                name: dto.name,
                emoji: dto.emoji,
                isIncome: dto.isIncome
            )
            container.mainContext.insert(e)
        }

        try container.mainContext.save()
    }
}


