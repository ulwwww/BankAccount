//
//  BankAccountsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

final class BankAccountsService {
    private let networkClient: NetworkClient
    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    func getAllAccounts() async throws -> [BankAccount] {
        let dtos: [BankAccountDTO] = try await networkClient.request(method: .get, path: "accounts")
        return dtos.map { $0.toDomain() }
    }

    func getAccount(id: Int) async throws -> BankAccount {
        let dtos: BankAccountDTO = try await networkClient.request(method: .get, path: "accounts/\(id)")
        return dtos.toDomain()
    }

    func updateAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        let dtos: BankAccountDTO = try await networkClient.request(method: .put, path: "accounts/\(newAccount.id)", body: newAccount)
        return dtos.toDomain()
    }
    
    public func createAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        let dtos: BankAccountDTO = try await networkClient.request(method: .post, path: "accounts", body: newAccount)
        return dtos.toDomain()
    }
}


