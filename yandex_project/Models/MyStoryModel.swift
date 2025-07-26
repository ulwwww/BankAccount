//
//  MyStoryModel.swift
//  yandex_project
//
//  Created by ulwww on 24.06.25.
//
import SwiftUI
import Utilities

final class MyStoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var emojiMap: [Int: String] = [:]
    @Published var sortOption: SortOption = .date
    @Published var isLoading = false
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var accountId: Int? = nil

    enum SortOption: CaseIterable, Identifiable {
        case date, amount
        var id: Self { self }
        var title: String {
            switch self {
            case .date:   return "По дате"
            case .amount: return "По сумме"
            }
        }
    }

    @Published var direction: Direction
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    private let calendar: Calendar
    @Published var pieChartEntities: [PieChartEntity] = []
    @Published var totalSum: Decimal = 0

    var sortedTransactions: [Transaction] {
        switch sortOption {
        case .date:   return transactions.sorted { $0.createdAt > $1.createdAt }
        case .amount: return transactions.sorted { $0.amount > $1.amount }
        }
    }

    init(direction: Direction, calendar: Calendar = .current) {
        self.direction = direction
        self.calendar = calendar
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        self._startDate = Published(initialValue: calendar.startOfDay(for: monthAgo))
        self._endDate = Published(initialValue: calendar.startOfDay(for: now))

        let client = NetworkClient(
            baseURL: URL(string: "https://shmr-finance.ru/api/v1/")!,
            token: "NAMSSUiLh9AGS534c5Rxlwww"
        )
        self.transactionsService = TransactionsService(networkClient: client)
        self.categoriesService = CategoriesService(networkClient: client)
        Task {
            await fetchAccountId()
            await loadData()
        }
    }

    @MainActor
    private func fetchAccountId() async {
        do {
            let id = try await transactionsService.currentAccountId()
            self.accountId = id
        } catch {
            print("Не удалось получить accountId:", error)
        }
    }

    @MainActor
    func loadData() async {
        guard !isLoading else { return }
        guard let id = accountId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let cats = try await categoriesService.categories()
            let emojis = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, String($0.emoji)) })
            let incomeMap = Dictionary(uniqueKeysWithValues:
                cats.map { ($0.id, $0.isIncome == .income) }
            )
            let names = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
            self.emojiMap = emojis

            let (start, end) = dateInterval(from: startDate, to: endDate)
            let all = try await transactionsService.transactions(from: start, to: end)

            let filtered = all.filter { tx in
                guard let isInc = incomeMap[tx.categoryId] else { return false }
                return direction == .income ? isInc : !isInc
            }
            self.transactions = filtered

            let sum = filtered.reduce(Decimal(0)) { acc, tx in acc + tx.amount }
            self.totalSum = sum
            let sumsByCategory = Dictionary(grouping: filtered, by: \.categoryId)
                .mapValues { txs in txs.reduce(Decimal(0)) { $0 + $1.amount } }

            self.pieChartEntities = sumsByCategory.map { (catId, value) in
                let name = names[catId] ?? "Неизвестная категория"
                return PieChartEntity(value: value, label: "\(name)")
            }

        } catch {
            print("MyStoryViewModel.loadData error:", error)
        }
    }

    func updateStartDate(to newDate: Date) {
        let normalized = calendar.startOfDay(for: newDate)
        startDate = normalized
        if normalized > endDate {
            endDate = normalized
        }
        Task { await loadData() }
    }

    func updateEndDate(to newDate: Date) {
        let normalized = calendar.startOfDay(for: newDate)
        endDate = normalized
        if normalized < startDate {
            startDate = normalized
        }
        Task { await loadData() }
    }

    private func dateInterval(from start: Date, to end: Date) -> (Date, Date) {
        let s = calendar.startOfDay(for: start)
        let eStart = calendar.startOfDay(for: end)
        let e = calendar.date(
            byAdding: DateComponents(hour: 23, minute: 59, second: 59),
            to: eStart
        )!
        return (s, e)
    }

    func percentage(for tx: Transaction) -> Double {
        let total = NSDecimalNumber(decimal: totalSum).doubleValue
        guard total > 0 else { return 0 }
        let value = NSDecimalNumber(decimal: tx.amount).doubleValue
        return value / total
    }
}
