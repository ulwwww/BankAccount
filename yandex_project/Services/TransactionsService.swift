//
//  TransactionsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

public class EmptyResponse: Codable {}

final class TransactionsService {
    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    public func createTransaction(_ newTransaction: Transaction) async throws -> Transaction {
        let requestDTO = TransactionDTO.fromDomain(newTransaction)
        let responseDTO: TransactionDTO = try await networkClient.request(
            method: .post,
            path: "transactions",
            body: requestDTO
        )
        return responseDTO.toDomain()
    }
    
    public func getTransaction(id: Int) async throws -> Transaction {
        let responseDTO: TransactionDTO = try await networkClient.request(
            method: .get,
            path: "transactions/\(id)"
        )
        return responseDTO.toDomain()
    }
    
    public func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        let requestDTO = TransactionDTO.fromDomain(transaction)
        let responseDTO: TransactionDTO = try await networkClient.request(
            method: .put,
            path: "transactions/\(transaction.id)",
            body: requestDTO
        )
        return responseDTO.toDomain()
    }

    public func deleteTransaction(id: Int) async throws {
        _ = try await networkClient.request(
            method: .delete,
            path: "transactions/\(id)"
        ) as EmptyResponse
    }

    public func transactions(
            accountId: Int,
            from startDate: Date,
            to endDate: Date
        ) async throws -> [Transaction] {
            let basePath = "transactions/account/\(accountId)/period"
            let endpointURL = networkClient.baseURL
                .appendingPathComponent(basePath)
            let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let fromStr = formatter.string(from: startDate)
                let toStr   = formatter.string(from: endDate)
            var comps = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                URLQueryItem(name: "from", value: fromStr),
                URLQueryItem(name: "to", value: toStr)
            ]
            let url = comps.url!
            let dtos: [TransactionDTO] = try await networkClient.request(
                url: url,
                method:  .get,
                responseType: [TransactionDTO].self
            )
            return dtos.map { $0.toDomain() }
        }
}
