//
//  Category.swift
//  yandex_project
//
//  Created by ulwww on 09.06.25.
//
import Foundation

struct Category: Identifiable {
    let id: Int
    let name: String
    let emoji: Character
    let isIncome: Direction
}

enum Direction: String, Codable {
    case income
    case outcome
}
