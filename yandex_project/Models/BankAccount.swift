//
//  BankAccount.swift
//  yandex_project
//
//  Created by ulwww on 09.06.25.
//
import Foundation

struct BankAccount {
    let id: Int
    let userId: Int
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date?
    let updatedAt: Date?
    
    enum KeyForAccountBrief: String, CodingKey {
        case id
        case userId
        case name
        case balance
        case currency
        case createdAt
        case updatedAt
    }
    
    init(id: Int, userId: Int, name: String, balance: Decimal, currency: String, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let dateFormatter = ISO8601DateFormatter()
        let keyedContainer = try decoder.container(keyedBy: KeyForAccountBrief.self)
        id = try keyedContainer.decode(Int.self, forKey: .id)
        name = try keyedContainer.decode(String.self, forKey: .name)
        userId = try keyedContainer.decode(Int.self, forKey: .userId)
        let balanceStr = try keyedContainer.decode(String.self, forKey: .balance)
        guard let d = Decimal(string: balanceStr) else {
              throw DecodingError.dataCorruptedError(forKey: .balance, in: keyedContainer, debugDescription: "error convert to Decimal")
        }
        balance = d
        currency = try keyedContainer.decode(String.self, forKey: .currency)
        let createdAtStr = try keyedContainer.decode(String.self, forKey: .createdAt)
        guard let createdAtVal = dateFormatter.date(from: createdAtStr) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: keyedContainer, debugDescription: "error date format")
        }
        createdAt = createdAtVal
        let updatedAtStr = try keyedContainer.decode(String.self, forKey: .updatedAt)
        guard let updatedAtVal = dateFormatter.date(from: updatedAtStr) else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: keyedContainer, debugDescription: "error date format")
        }
        updatedAt = updatedAtVal
    }
}


