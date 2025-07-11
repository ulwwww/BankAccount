//
//  MyStoryModel.swift
//  yandex_project
//
//  Created by ulwww on 24.06.25.
//
import SwiftUI

final class MyStoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var emojiMap: [Int: String] = [:]
    @Published var sortOption: SortOption = .date
    @Published var flagLoading = false
    @Published var startDate: Date
    @Published var endDate: Date

    enum SortOption: CaseIterable, Identifiable {
        case date, amount
        var id: Self { self }
        var title: String {
            switch self {
            case .date: return "По дате"
            case .amount: return "По сумме"
            }
        }
    }

    let direction: Direction
    private let service = TransactionsService()
    private let calendar: Calendar

    init(direction: Direction, calendar: Calendar = .current) {
        self.direction = direction
        self.calendar = calendar
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        self._startDate = Published(initialValue: calendar.startOfDay(for: monthAgo))
        self._endDate = Published(initialValue: calendar.startOfDay(for: now))
        Task { await loadData() }
    }

    var totalSum: Decimal {
        transactions.map(\.amount).reduce(0, +)
    }

    var sortedTransactions: [Transaction] {
        switch sortOption {
        case .date: return transactions.sorted { $0.createdAt > $1.createdAt }
        case .amount: return transactions.sorted { $0.amount > $1.amount }
        }
    }

    @MainActor
    func loadData() async {
        guard !flagLoading else { return }
        flagLoading = true
        defer {
            flagLoading = false
        }
        let (start, end) = dateInterval(from: startDate, to: endDate)
        let categories = service.categories
        emojiMap = categories.reduce(into: [:]) { $0[$1.id] = String($1.emoji) }

        do {
            let all = try await service.takeTransaction(from: start, to: end)
            let incomeMap = categories.reduce(into: [:]) { $0[$1.id] = $1.isIncome }
            transactions = all.filter {
                guard let dir = incomeMap[$0.categoryId] else { return false }
                return direction == .income ? dir == .income : dir == .outcome
            }
        } catch {
        }
    }

    func updateStartDate(to newDate: Date) {
        let normalized = calendar.startOfDay(for: newDate)
        startDate = normalized
        if normalized > endDate {
            endDate = normalized
        }
    }

    func updateEndDate(to newDate: Date) {
        let normalized = calendar.startOfDay(for: newDate)
        endDate = normalized
        if normalized < startDate {
            startDate = normalized
        }
    }

    private func dateInterval(from start: Date, to end: Date) -> (Date, Date) {
        let s = calendar.startOfDay(for: start)
        let eStart = calendar.startOfDay(for: end)
        let e = calendar.date(byAdding: DateComponents(hour: 23, minute: 59, second: 59), to: eStart)!
        return (s, e)
    }
    func percentage(for tx: Transaction) -> Double {
        let total = NSDecimalNumber(decimal: totalSum).doubleValue
        guard total > 0 else { return 0 }
        let value = NSDecimalNumber(decimal: tx.amount).doubleValue
        return value / total
    }
}


