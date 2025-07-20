//
//  TransactionsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
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

@MainActor
protocol BackupStorage {
    func add(transaction: Transaction?, transactionId: Int?, for op: OperationType) async throws
    func pendingOperations() async throws -> [BackupOperation]
    func remove(id: Int) async throws
}

final class TransactionsService {
    private let networkClient: NetworkClient
    @MainActor private lazy var storage: TransactionsStorage = SwiftDataTransactionsStorage()
    @MainActor private lazy var backup: BackupStorage = SwiftDataBackupStorage()
    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    public func transactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        await syncIfNeeded()
        let queryItems = [
            URLQueryItem(name: "startDate", value: Self.dateOnlyFormatter.string(from: startDate)),
            URLQueryItem(name: "endDate", value: Self.dateOnlyFormatter.string(from: endDate))
        ]
        let url = try makeURL(path: "transactions/account/\(accountId)/period", query: queryItems)
        do {
            let dtos: [TransactionDTO] = try await networkClient.request(
                url: url,
                method: .get,
                responseType: [TransactionDTO].self
            )
            let txns = dtos.map { $0.toDomain() }
            try await storage.sync(transactions: txns)
            return txns.filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
        } catch {
            let local = try await storage.fetchAll().filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
            throw TransactionsServiceError.networkFallback(local, error)
        }
    }

    public func createTransaction(_ txn: Transaction) async throws -> Transaction {
        try await performBackupable(.add, txn, txn.id) {
            let dto = TransactionDTO.fromDomain(txn)
            let response: TransactionDTO = try await self.networkClient.request(
                method: .post,
                path: "transactions",
                body: dto
            )
            let created = response.toDomain()
            try await self.storage.create(created)
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
            try await self.storage.update(updated)
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

    private func makeURL(path: String, query: [URLQueryItem]?) throws -> URL {
        let base = networkClient.baseURL.appendingPathComponent(path)
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw TransactionsServiceError.urlError
        }
        comps.queryItems = query
        guard let url = comps.url else {
            throw TransactionsServiceError.urlError
        }
        return url
    }

    private func syncIfNeeded() async {
        do {
            try await syncBackupToServer()
        } catch { print(error) }
    }

    private func performBackupable<T>(_ op: OperationType, _ txn: Transaction?, _ id: Int?, block: @escaping () async throws -> T) async throws -> T {
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
            do {
                switch entry.type {
                case .add:
                    if let t = entry.payload { _ = try await createTransaction(t) }
                case .update:
                    if let t = entry.payload { _ = try await updateTransaction(t) }
                case .delete:
                    if let tid = entry.payloadTransactionId { try await deleteTransaction(id: tid) }
                }
                try await backup.remove(id: entry.id)
            } catch {
                print(error)
            }
        }
    }
}
