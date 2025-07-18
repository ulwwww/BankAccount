//
//  Protocols.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//

@MainActor
protocol TransactionsStorage {
    func fetchAll() throws -> [Transaction]
    func create(_ transaction: Transaction) throws
    func update(_ transaction: Transaction) throws
    func delete(id: Int) throws
}

@MainActor
protocol TransactionsBackUpStorage {
    func fetchAll() throws -> [BackupOperation]
    func saveBackupOperation(_ op: BackupOperation) throws
    func clearSyncedOperations(ids: [Int]) throws
}

@MainActor
protocol BankAccountsStorage {
    func fetchAll() throws -> [BankAccount]
    func create(_ account: BankAccount) throws
    func update(_ account: BankAccount) throws
    func delete(id: Int) throws
}

@MainActor
protocol BankAccountsBackUpStorage {
    func fetchAll() throws -> [BackupOperation]
    func saveBackupOperation(_ op: BackupOperation) throws
    func clearSyncedOperations(ids: [Int]) throws
}

@MainActor
protocol CategoriesStorage {
    func fetchAll() throws -> [Category]
    func saveAll(_ categories: [Category]) throws
}

