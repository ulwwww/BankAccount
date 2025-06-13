//
//  CategoriesService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//

final class CategoriesService {
    func categories() async throws -> [Category] {
        [
            Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: Direction.income),
            Category(id: 2, name: "Подарки", emoji: "🎁", isIncome: Direction.income),
            Category(id: 3, name: "Еда", emoji: "🍔", isIncome: Direction.outcome),
            Category(id: 4, name: "Развлечения", emoji: "🎬", isIncome: Direction.outcome),
        ]
    }
    
    func categories(direction: Direction) async throws -> [Category] {
        let all = try await categories()
        switch direction {
        case .income:
            return all.filter { $0.isIncome == Direction.income }
        case .outcome:
            return all.filter { $0.isIncome == Direction.outcome }
        }
    }
}
