//
//  CategoryDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
import Foundation

struct CategoryDTO: Codable {
    public let id: Int
    public let name: String
    public let emoji: String
    public let isIncome: Bool
}

extension CategoryDTO {
    func toDomain() -> Category {
        return Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "?",
            isIncome: isIncome ? .income : .outcome
        )
    }
}


