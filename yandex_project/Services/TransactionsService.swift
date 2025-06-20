//
//  TransactionsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

final class TransactionsService {
    let testDate = Calendar.current.date(
        from: DateComponents(year: 2025, month: 5, day: 20, hour: 20, minute: 30)
    )!
    
    let categories: [Category] = [
        Category(id: 1,  name: "Аренда квартиры", emoji: "🏠",  isIncome: Direction.outcome),
        Category(id: 2,  name: "Одежда", emoji: "👗", isIncome: Direction.outcome),
        Category(id: 3,  name: "На собачку", emoji: "🐶", isIncome: Direction.outcome),
        Category(id: 4,  name: "На собачку", emoji: "🐕", isIncome: Direction.outcome),
        Category(id: 5,  name: "Ремонт квартиры", emoji: "🛠️", isIncome: Direction.outcome),
        Category(id: 6,  name: "Спортзал", emoji: "🏋️", isIncome: Direction.outcome),
        Category(id: 7,  name: "Аптека", emoji: "💊", isIncome: Direction.outcome),
        Category(id: 8,  name: "Зарплата", emoji: "💰", isIncome: Direction.income),
        Category(id: 9,  name: "Подработка", emoji: "⚒️", isIncome: Direction.income),
        Category(id: 10, name: "Страховая выплата", emoji: "🛡️", isIncome: Direction.income),
    ]

    lazy var transactions: [Transaction] = [
        Transaction(id: 1, accountId: 1, categoryId: categories[0].id, amount: Decimal(string: "100.00")!, comment: "Продукты",               transactionDate: testDate, createdAt: testDate, updatedAt: testDate),
        Transaction(id: 2, accountId: 2, categoryId: categories[1].id, amount: Decimal(string: "110.00")!, comment: "Спортзал",               transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 3, accountId: 3, categoryId: categories[2].id, amount: Decimal(string: "120.00")!, comment: "Развлечения",            transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 4, accountId: 4, categoryId: categories[3].id, amount: Decimal(string: "150.00")!, comment: "На собачку",             transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 5, accountId: 1, categoryId: categories[4].id, amount: Decimal(string: "2000.00")!, comment: "Ремонт балкона",     transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 6, accountId: 1, categoryId: categories[5].id, amount: Decimal(string: "750.10")!,  comment: "Абонемент в зал",     transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 7, accountId: 2, categoryId: categories[6].id, amount: Decimal(string: "320.00")!,  comment: "Лекарства",          transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 8, accountId: 2, categoryId: categories[7].id, amount: Decimal(string: "50000.00")!, comment: "Зарплата за сентябрь", transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 9, accountId: 3, categoryId: categories[8].id, amount: Decimal(string: "8000.00")!,  comment: "Фриланс-проект",     transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 10, accountId: 3, categoryId: categories[9].id, amount: Decimal(string: "1200.00")!, comment: "Компенсация страховой",transactionDate: Date(), createdAt: Date(), updatedAt: Date())
    ]
    
    func createTransaction(_ new: Transaction) async throws -> Transaction {
        transactions.append(new)
        return new
    }
    
    func takeTransaction(from start: Date, to end: Date) async throws -> [Transaction] {
        guard start <= end else {
            throw ErrorService.invalidDateRange
        }
        let ans = transactions.filter() {
            let date = $0.transactionDate
            return date >= start && date <= end
        }
        return ans
    }
    
    func editTransaction(_ transaction: Transaction) async throws -> Transaction {
        guard let ind = transactions.firstIndex(where: {$0.id == transaction.id}) else {
            throw ErrorService.transactionNotFound(id: transaction.id)
        }
        transactions[ind] = transaction
        return transaction
    }
    
    func removeTransaction(_ ind: Int) async throws {
        guard let ind = transactions.firstIndex(where: {$0.id == ind}) else {
            throw ErrorService.transactionNotFound(id: ind)
        }
        transactions.remove(at: ind)
    }
}
