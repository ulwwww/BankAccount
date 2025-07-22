//
//  TransactionsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
//
import Foundation
import SwiftData

enum TransactionsServiceError: Error {
    case urlError
    case networkFallback([Transaction], Error)
}

public class EmptyResponse: Codable {}

public struct BackupOperation: Codable {
    let id: Int
    let type: OperationType
    let payload: Transaction?
    let payloadTransactionId: Int?
}

final class TransactionsService {
    private let networkClient: NetworkClient
    private lazy var bankAccountService: BankAccountsService = {
        BankAccountsService(networkClient: self.networkClient)
    }()
    private var storage: TransactionsStorageProtocol = StorageManager.shared.transactions
    private var backup: BackupStorageProtocol = StorageManager.shared.backup
    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    private func currentAccountId() async throws -> Int {
        try await bankAccountService.currentIdAccount()
    }

    public func transactions(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let accountId = try await currentAccountId()
        await syncIfNeeded()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let utcStart = calendar.startOfDay(for: startDate)
        let utcEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        let queryItems = [
            URLQueryItem(name: "startDate", value: Self.dateOnlyFormatter.string(from: utcStart)),
            URLQueryItem(name: "endDate", value: Self.dateOnlyFormatter.string(from: utcEnd))
        ]

        do {
            let apiResponses: [APITransactionResponse] = try await networkClient.request(
                method: .get,
                path:   "transactions/account/\(accountId)/period",
                queryItems: queryItems
            )

            let txns = apiResponses.map { api in
                Transaction(
                    id: api.id,
                    accountId: api.account.id,
                    categoryId: api.category.id,
                    amount: Decimal(string: api.amount) ?? .zero,
                    comment: api.comment ?? "",
                    transactionDate: api.parsedTransactionDate,
                    createdAt: api.parsedCreatedAt,
                    updatedAt: api.parsedUpdatedAt
                )
            }

            try await storage.sync(transactions: txns)
            return txns
        } catch {
            let local = try await storage.getAll()
            let filtered = local.filter {
                $0.transactionDate >= utcStart && $0.transactionDate < utcEnd
            }
            throw TransactionsServiceError.networkFallback(filtered, error)
        }
    }

    public func createTransaction(_ txn: Transaction) async throws -> Transaction {
        try await performBackupable(.add, txn, txn.id) {
            let request = CreateTransactionRequest(
                accountId: txn.accountId,
                categoryId: txn.categoryId,
                amount: "\(txn.amount)",
                transactionDate: txn.transactionDate,
                comment: txn.comment
            )
            let response: APITransactionResponse = try await self.networkClient.request(
                method: .post,
                path: "transactions",
                body: request
            )
            let created = Transaction(
                id: response.id,
                accountId: response.account.id,
                categoryId: response.category.id,
                amount: Decimal(string: response.amount) ?? .zero,
                comment: response.comment ?? "",
                transactionDate: response.parsedTransactionDate,
                createdAt: response.parsedCreatedAt,
                updatedAt: response.parsedUpdatedAt
            )

            try await self.storage.create(transaction: created)
            return created
        }
    }

    public func updateTransaction(_ txn: Transaction) async throws -> Transaction {
        try await performBackupable(.update, txn, txn.id) {
            let dto = TransactionDTO.fromDomain(txn)
            let response: TransactionDTO = try await self.networkClient.request(
                method: .put,
                path: "transactions/\(txn.id)",
                body: dto
            )
            let updated = response.toDomain()
            try await self.storage.update(transaction: updated)
            return updated
        }
    }

    public func deleteTransaction(id: Int) async throws {
        try await performBackupable(.delete, nil, id) {
            let _: EmptyResponse = try await self.networkClient.request(
                method: .delete,
                path: "transactions/\(id)"
            )
            try await self.storage.delete(id: id)
        }
    }

    private func syncIfNeeded() async {
        do {
            try await syncBackupToServer()
        } catch {
            print("sync failed: \(error)")
        }
    }

    private func performBackupable<T>(_ op: OperationType, _ txn: Transaction?, _ id: Int?, block: @escaping () async throws -> T
    ) async throws -> T {
        do {
            return try await block()
        } catch {
            try await backup.add(transaction: txn, transactionId: id, for: op)
            throw error
        }
    }

    public func syncBackupToServer() async throws {
        let pending = try await backup.pendingOperations()
        for entry in pending {
            switch entry.type {
            case .add:
                if let t = entry.payload { _ = try await createTransaction(t) }
            case .update:
                if let t = entry.payload { _ = try await updateTransaction(t) }
            case .delete:
                if let tid = entry.payloadTransactionId { try await deleteTransaction(id: tid) }
            }
            try await backup.remove(id: entry.id)
        }
    }
}
