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
final class SwiftDataTransactionsStorage: TransactionsStorageProtocol {
    private let modelContext: ModelContext

    nonisolated init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

    func getAll() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>()
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toTransaction() }
    }

    func getTransactions(from start: Date? = nil, to end: Date? = nil) async throws -> [Transaction] {
            var predicates: [Predicate<TransactionEntity>] = []

            if let s = start {
                predicates.append(#Predicate { $0.transactionDate >= s })
            }
            if let e = end {
                predicates.append(#Predicate { $0.transactionDate <= e })
            }
            let combinedPredicate: Predicate<TransactionEntity>
            switch predicates.count {
            case 0:
                combinedPredicate = #Predicate { _ in true }
            case 1:
                combinedPredicate = predicates[0]
            default:
                combinedPredicate = predicates.dropFirst().reduce(predicates[0]) { acc, pred in
                    #Predicate { acc.evaluate($0) && pred.evaluate($0) }
                }
            }
            let descriptor = FetchDescriptor<TransactionEntity>(
                predicate: combinedPredicate,
                sortBy: [SortDescriptor(\TransactionEntity.transactionDate, order: .forward)]
            )
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toTransaction() }
        }

    func create(transaction: Transaction) async throws {
        let entity = TransactionEntity(from: transaction)
        modelContext.insert(entity)
        try modelContext.save()
    }

    func update(transaction: Transaction) async throws {
        let fetch = FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.id == transaction.id })
        if let ex = try modelContext.fetch(fetch).first {
            ex.account = transaction.accountId
            ex.category = transaction.categoryId
            ex.amount = transaction.amount
            ex.transactionDate = transaction.transactionDate
            ex.comment = transaction.comment
            ex.createdAt = transaction.createdAt
            ex.updatedAt = transaction.updatedAt
            try modelContext.save()
        }
    }

    func delete(id: Int) async throws {
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.id == id })
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func sync(transactions: [Transaction]) async throws {
        var descriptor = FetchDescriptor<TransactionEntity>()
        let existingEntities = try modelContext.fetch(descriptor)
        let existingId = Dictionary(uniqueKeysWithValues: existingEntities.map { ($0.id, $0) })
        let incoming = Set(transactions.map(\.id))
        for txn in transactions {
            if let entity = existingId[txn.id] {
            entity.account = txn.accountId
            entity.category = txn.categoryId
            entity.amount = txn.amount
            entity.transactionDate  = txn.transactionDate
            entity.comment = txn.comment
            entity.createdAt  = txn.createdAt
            entity.updatedAt = txn.updatedAt
            } else {
                let newEntity = TransactionEntity(from: txn)
                modelContext.insert(newEntity)
            }
        }
        for entity in existingEntities where !incoming.contains(entity.id) {
            modelContext.delete(entity)
        }
        return try modelContext.save()
    }
}

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorageProtocol {
    private let modelContext: ModelContext

    nonisolated init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

    func getAllCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>()
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toCategory() }
    }

    func getCategories(by direction: Direction) async throws -> [Category] {
        let isIncomeFlag = (direction == .income)
        let predicate: Predicate<CategoryEntity> = #Predicate { entity in
                entity.isIncome == isIncomeFlag
        }
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: predicate)

        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toCategory() }
    }

    func saveCategories(_ categories: [Category]) async throws {
        let old = try modelContext.fetch(FetchDescriptor<CategoryEntity>())
        for obj in old { modelContext.delete(obj) }
        for cat in categories { modelContext.insert(CategoryEntity(from: cat)) }
        try modelContext.save()
    }
}

@MainActor
final class SwiftDataAccountStorage: BankAccountStorageProtocol {
    private let modelContext: ModelContext

    nonisolated init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

    func getAccount() async throws -> BankAccount {
        let descriptor = FetchDescriptor<BankAccountEntity>()
        if let entity = try modelContext.fetch(descriptor).first {
            return entity.toBankAccount()
        }
        throw NSError(domain: "AccountStorage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account not found"])
    }

    func updateAccount(amount: Decimal, currencyCode: String) async throws {
        let descriptor = FetchDescriptor<BankAccountEntity>()
        if let entity = try modelContext.fetch(descriptor).first {
            entity.balance = "\(amount)"
            entity.currency = currencyCode
            entity.updatedAt = Date()
            try modelContext.save()
        }
    }

    func saveAccount(account: BankAccount) async throws {
        let descriptor = FetchDescriptor<BankAccountEntity>()
        let existing = try modelContext.fetch(descriptor)
        for entity in existing {
            modelContext.delete(entity)
        }
        let newEntity = BankAccountEntity(from: account)
        modelContext.insert(newEntity)
        try modelContext.save()
    }


    func getCurrentAccountId() async throws -> Int {
        let descriptor = FetchDescriptor<BankAccountEntity>()
        if let entity = try modelContext.fetch(descriptor).first {
            return entity.id
        }
        throw NSError(domain: "AccountStorage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account not found"])
    }
}

@MainActor
final class SwiftDataBackupStorage: BackupStorageProtocol {
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    nonisolated init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

    func add(
        transaction: Transaction?,
        transactionId: Int?,
        for op: OperationType
    ) async throws {
        let newId = Int(Date().timeIntervalSince1970 * 1_000)
        let data = transaction.flatMap { try? encoder.encode($0) }
        let entity = BackupOperationEntity(
            id: newId,
            type: op,
            payloadData: data,
            payloadTransactionId: transactionId!
        )
        modelContext.insert(entity)
        try modelContext.save()
    }

    func pendingOperations() async throws -> [BackupOperation] {
        let desc = FetchDescriptor<BackupOperationEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let entities = try modelContext.fetch(desc)
        return entities.map { ent in
            let txn: Transaction? = ent.payloadData.flatMap {
                try? decoder.decode(Transaction.self, from: $0)
            }
            return BackupOperation(
                id: ent.id,
                type: ent.type,
                payload: txn,
                payloadTransactionId: ent.payloadTransactionId
            )
        }
    }

    func remove(id: Int) async throws {
        let desc = FetchDescriptor<BackupOperationEntity>(
            predicate: #Predicate { $0.id == id }
        )
        if let ent = try modelContext.fetch(desc).first {
            modelContext.delete(ent)
            try modelContext.save()
        }
    }
}
