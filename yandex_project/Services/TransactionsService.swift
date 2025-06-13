//
//  TransactionsService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

final class TransactionsService {
    
    private var transactions: [Transaction] = [
        Transaction(id: 1, accountId: 1, categoryId: 1, amount: Decimal(string: "100.00")!, comment: "Продукты", transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 2, accountId: 2, categoryId: 2, amount: Decimal(string: "110.00")!, comment: "Спортзал",
            transactionDate: Date(), createdAt: Date(), updatedAt: Date())
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
