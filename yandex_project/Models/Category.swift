//
//  Category.swift
//  yandex_project
//
//  Created by ulwww on 09.06.25.
//
import Foundation

import Foundation

struct Category: Identifiable, Decodable {
    public let id: Int
    public let name: String
    public let emoji: Character
    public let isIncome: Direction

    public init(
        id: Int,
        name: String,
        emoji: Character,
        isIncome: Direction
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case emoji
        case isIncome
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let emojiString = try container.decode(String.self, forKey: .emoji)
        emoji = emojiString.first ?? "?"
        let flag = try container.decode(Bool.self, forKey: .isIncome)
        isIncome = flag ? .income : .outcome
    }
}

enum Direction: String, Codable {
    case income
    case outcome
}
