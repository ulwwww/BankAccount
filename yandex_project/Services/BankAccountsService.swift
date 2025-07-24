//
//  BankAccountsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

final class BankAccountsService {
    private let networkClient: NetworkClient
    private var storage = StorageManager.shared.account
    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    public func getAllAccounts() async throws -> [BankAccount] {
        do {
            let dtos: [BankAccountDTO] = try await networkClient.request(method: .get, path: "accounts")
            let domains = dtos.map { $0.toDomain() }
            if let first = domains.first {
                try await storage.saveAccount(account: first)
            }
            return domains
        } catch {
            do {
                let local = try await storage.getAccount()
                return [local]
            } catch {
                throw ErrorService.bankAccountError
            }
        }
    }

    public func getAccount() async throws -> BankAccount {
        do {
        let dtos: [BankAccountDTO] = try await networkClient.request(method: .get, path: "accounts")
        guard let dto = dtos.first else {
                throw ErrorService.bankAccountError
        }
        let domain = dto.toDomain()
        try await storage.saveAccount(account: domain)
            print(domain.id)
        return domain
        } catch {
            do {
                return try await storage.getAccount()
            } catch {
                throw ErrorService.bankAccountError
            }
        }
    }
    
    public func updateAccount(currencyCode: String,newBalance: Decimal) async throws -> BankAccount {
        let current = try await getAccount()
        let requestDTO = AccountDTO( name: current.name, balance: "\(newBalance)", currency: currencyCode
        )
        let updatedDTO: BankAccountDTO = try await networkClient.request(method: .put, path: "accounts/\(current.id)", body: requestDTO)
        let updated = updatedDTO.toDomain()
        try await storage.updateAccount(amount: updated.balance, currencyCode: updated.currency)
        return updated
    }

    public func createAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        let createdDTO: BankAccountDTO = try await networkClient.request( method: .post, path: "accounts", body: newAccount)
        let created = createdDTO.toDomain()
        try await storage.saveAccount(account: created)
        return created
    }

    public func currentIdAccount() async throws -> Int {
        do {
            let accountCurrent = try await getAccount()
            return accountCurrent.id
        } catch ErrorService.bankAccountError {
            return try await storage.getCurrentAccountId()
        }
    }
}


