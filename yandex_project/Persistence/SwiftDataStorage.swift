//
//  SwiftDataStorage.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//
import SwiftData
import Foundation

struct PendingBackupTransaction {
    let id: Int
    let operation: OperationType
    let transaction: Transaction?
    let transactionId: Int
}

enum StorageError: Error {
    case notFound
    case containerError
}


@MainActor
final class SwiftDataTransactionsStorage: TransactionsStorage {
    func sync(transactions: [Transaction]) async throws {
        return try await createStorageSync(transactions)
    }
    
    private let container = PersistenceController.shared.modelContainer

    func fetchAll() async throws -> [Transaction] {
        let ents = try container.mainContext.fetch(FetchDescriptor<TransactionEntity>())
        return ents.map { $0.toDomain() }
    }

    func createStorageSync(_ transactions: [Transaction]) async throws {
        let old = try container.mainContext.fetch(FetchDescriptor<TransactionEntity>())
        old.forEach(container.mainContext.delete)
        transactions.forEach { container.mainContext.insert(TransactionEntity(from: $0)) }
        try container.mainContext.save()
    }

    func create(_ transaction: Transaction) async throws {
        let e = TransactionEntity(from: transaction)
        container.mainContext.insert(e)
        try container.mainContext.save()
    }

    func update(_ transaction: Transaction) async throws {
        let desc = FetchDescriptor<TransactionEntity>(predicate: #Predicate<TransactionEntity> { $0.id == transaction.id })
        guard let e = try container.mainContext.fetch(desc).first else { throw StorageError.notFound }
        e.update(from: transaction)
        try container.mainContext.save()
    }

    func delete(id: Int) async throws {
        let desc = FetchDescriptor<TransactionEntity>(predicate: #Predicate<TransactionEntity> { $0.id == id })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach(container.mainContext.delete)
        try container.mainContext.save()
    }
}




@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorage {
    private let container: ModelContainer
    init(container: ModelContainer) { self.container = container }

    func fetchAll() async throws -> [BankAccount] {
        let ents = try container.mainContext.fetch(FetchDescriptor<BankAccountEntity>())
        return ents.map { $0.toDomain() }
    }

    func create(_ account: BankAccount) async throws {
        let e = BankAccountEntity(from: account)
        container.mainContext.insert(e)
        try container.mainContext.save()
    }
    
    func update(_ account: BankAccount) async throws {
        let desc = FetchDescriptor<BankAccountEntity>(predicate: #Predicate<BankAccountEntity> { $0.id == account.id })
        guard let e = try container.mainContext.fetch(desc).first else { throw StorageError.notFound }
        e.update(from: account)
        try container.mainContext.save()
    }

    func delete(id: Int) async throws {
        let desc = FetchDescriptor<BankAccountEntity>(predicate: #Predicate<BankAccountEntity> { $0.id == id })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach(container.mainContext.delete)
        try container.mainContext.save()
    }
}

@MainActor
final class SwiftDataBankAccountsBackUpStorage: BankAccountsBackUpStorage {
    private let container: ModelContainer

    init(container: ModelContainer) { self.container = container }

    func fetchAll() async throws -> [BackupOperation] {
        let ents = try container.mainContext.fetch(FetchDescriptor<BackupAccountOperationEntity>())
        return ents.map { e in
            BackupOperation(
                id: e.id,
                type: e.type,
                payload: nil,
                payloadTransactionId: e.payloadAccountId
            )
        }
    }
    
    func saveBackupOperation(_ op: BackupOperation) async throws {
        let entity = BackupAccountOperationEntity(
            id: op.id,
            type: op.type,
            payloadAccountId: op.payloadTransactionId ?? 0
        )
        container.mainContext.insert(entity)
        try container.mainContext.save()
    }
    func clearSyncedOperations(ids: [Int]) async throws {
        let desc = FetchDescriptor<BackupAccountOperationEntity>(predicate: #Predicate<BackupAccountOperationEntity> { ids.contains($0.id) })
        let arr = try container.mainContext.fetch(desc)
        arr.forEach(container.mainContext.delete)
        try container.mainContext.save()
    }
}


@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorage {
    private let container: ModelContainer
    init(container: ModelContainer) { self.container = container }

    func fetchAll() async throws -> [Category] {
        let ents = try container.mainContext.fetch(FetchDescriptor<CategoryEntity>())
        return ents.map { $0.toDomain() }
    }

    func saveAll(_ categories: [Category]) async throws {
        let old = try container.mainContext.fetch(FetchDescriptor<CategoryEntity>())
        old.forEach(container.mainContext.delete)
        categories.forEach { container.mainContext.insert(CategoryEntity(from: $0)) }
        try container.mainContext.save()
    }
}

@MainActor
final class SwiftDataBackupStorage: BackupStorage {
    private let container = PersistenceController.shared.modelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    func add(transaction: Transaction?, transactionId: Int?, for op: OperationType) async throws {
        let entry = BackupOperationEntity(
            id: transactionId ?? Int(Date().timeIntervalSince1970),
            type: op,
            payload: transaction != nil ? try? encoder.encode(transaction) : nil,
            payloadTransactionId: transactionId
        )
        container.mainContext.insert(entry)
        try container.mainContext.save()
    }

    func pendingOperations() async throws -> [BackupOperation] {
        let ents = try container.mainContext.fetch(FetchDescriptor<BackupOperationEntity>())
        return ents.map { e in
            let txn: Transaction? = e.payload.flatMap { try? decoder.decode(Transaction.self, from: $0) }
            return BackupOperation(
                id: e.id,
                type: e.type,
                payload: txn,
                payloadTransactionId: e.payloadTransactionId
            )
        }
    }

    func remove(id: Int) async throws {
        let desc = FetchDescriptor<BackupOperationEntity>(predicate: #Predicate<BackupOperationEntity> { $0.id == id })
        if let e = try container.mainContext.fetch(desc).first {
            container.mainContext.delete(e)
            try container.mainContext.save()
        }
    }
}






