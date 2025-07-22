//
//  Protocols.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//
import Foundation


protocol BankAccountStorageProtocol {
    func getAccount() async throws -> BankAccount
    func updateAccount(amount: Decimal, currencyCode: String) async throws
    func saveAccount(account: BankAccount) async throws
    func getCurrentAccountId() async throws -> Int
}

protocol TransactionsStorageProtocol {
    func getAll() async throws -> [Transaction]
    func getTransactions(from: Date?, to: Date?) async throws -> [Transaction]
    func create(transaction: Transaction) async throws
    func update(transaction: Transaction) async throws
    func delete(id: Int) async throws
    func sync(transactions: [Transaction]) async throws
}

protocol CategoriesStorageProtocol {
    func getAllCategories() async throws -> [Category]
    func getCategories(by direction: Direction) async throws -> [Category]
    func saveCategories(_ categories: [Category]) async throws
}

protocol BackupStorageProtocol {
    func add(transaction: Transaction?, transactionId: Int?, for op: OperationType) async throws
    func pendingOperations() async throws -> [BackupOperation]
    func remove(id: Int) async throws
}
