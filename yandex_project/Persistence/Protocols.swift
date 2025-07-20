//
//  Protocols.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//

@MainActor
protocol TransactionsStorage {
    func fetchAll() async throws -> [Transaction]
    func create(_ transaction: Transaction) async throws
    func sync(transactions: [Transaction]) async throws
    func update(_ transaction: Transaction) async throws
    func delete(id: Int) async throws
}

@MainActor
protocol TransactionsBackUpStorage {
    func fetchAll() async throws -> [BackupOperation]
    func saveBackupOperation(_ op: BackupOperation) async throws
    func clearSyncedOperations(ids: [Int]) async throws
}

@MainActor
protocol BankAccountsStorage {
    func fetchAll() async throws -> [BankAccount]
    func create(_ account: BankAccount) async throws
    func update(_ account: BankAccount) async throws
    func delete(id: Int) async throws
}

@MainActor
protocol BankAccountsBackUpStorage {
    func fetchAll() async throws -> [BackupOperation]
    func saveBackupOperation(_ op: BackupOperation) async throws
    func clearSyncedOperations(ids: [Int]) async throws
}

@MainActor
protocol CategoriesStorage {
    func fetchAll() async throws -> [Category]
    func saveAll(_ categories: [Category]) async throws
}

