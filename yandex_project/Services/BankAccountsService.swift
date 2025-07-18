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
        try await networkClient.request(method: .get, path: "accounts")
    }

    func getAccount(id: Int) async throws -> BankAccount {
        try await networkClient.request(method: .get, path: "accounts/\(id)")
    }

    func updateAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        try await networkClient.request(method: .put, path: "accounts/\(newAccount.id)", body: newAccount)
    }
    
    public func createAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        try await networkClient.request(method: .post, path: "accounts", body: newAccount)
    }
}


