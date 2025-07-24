//
//  BankAccountDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//

import Foundation

struct BankAccountDTO: Codable {
    let id: Int
    let userId: Int
    let name: String
    let balance: String
    let currency: String
    let createdAt: String
    let updatedAt: String
}

extension BankAccountDTO {
    func toDomain() -> BankAccount {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: Decimal(string: balance) ?? .zero,
            currency: currency,
            createdAt: iso.date(from: createdAt) ?? Date(),
            updatedAt: iso.date(from: updatedAt) ?? Date()
        )
    }
}

