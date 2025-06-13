//
//  BankAccountsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

final class BankAccountsService {
    private var accounts: [BankAccount] = [
        BankAccount(id: 1, userId: 1, name: "Основной счёт", balance: Decimal(string: "113.50")!, currency: "₽", createdAt: Date(), updatedAt: Date()),
        BankAccount(id: 2, userId: 2, name: "Сбережения", balance: Decimal(string: "50022.10")!, currency: "₽", createdAt: Date(), updatedAt: Date())
    ]

    func getAllAccounts() async throws -> [BankAccount] {
        return accounts
    }

    func getAccount() async throws -> BankAccount {
        guard let first = accounts.first else {
            throw ErrorService.accountNotFound(id: 0)
        }
        return first
    }

    func updateAccount(_ newAccount: BankAccount) async throws -> BankAccount {
        guard let index = accounts.firstIndex(where: {$0.id == newAccount.id}) else {
            throw ErrorService.notFoundAllAccount
        }
        accounts[index] = newAccount
        return newAccount
    }
}


