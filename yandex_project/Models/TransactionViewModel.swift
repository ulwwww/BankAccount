//
//  Transaction.swift
//  yandex_project
//
//  Created by ulwww on 26.06.25.
//
import Foundation
import SwiftUI
import SwiftData

final class TransactionsListViewModel: ObservableObject {
    @Published var isLoading = false
    @Published private(set) var allTransactions: [Transaction] = []
    @Published var emojiMap: [Int: String] = [:]
    @Published var incomeMap: [Int: Bool] = [:]
    @Published var currency: CurrencyData = .rub {
        didSet { recalcDisplayedBalance() }
    }
    @Published private(set) var displayedBalance: Decimal = 0

    private var manualStartBalance: Decimal?
    private var computedBalanceAtManual: Decimal = 0

    private var computedBalanceFull: Decimal {
        let incomeSum = allTransactions
            .filter { incomeMap[$0.categoryId] == true }
            .map(\.amount)
            .reduce(0, +)
        let outcomeSum = allTransactions
            .filter { incomeMap[$0.categoryId] == false }
            .map(\.amount)
            .reduce(0, +)
        return incomeSum - outcomeSum
    }

    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    private let calendar = Calendar.current

    init() {
        let client = NetworkClient(
            baseURL: URL(string: "https://shmr-finance.ru/api/v1/")!,
            token: "NAMSSUiLh9AGS534c5Rxlwww"
        )
        self.transactionsService = TransactionsService(networkClient: client)
        self.categoriesService = CategoriesService(networkClient: client)

        Task { await loadData() }
    }

    @MainActor
    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let categories = try await categoriesService.categories()
            emojiMap  = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, String($0.emoji)) })
            incomeMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.isIncome == .income) })
        } catch {
            print("Failed to load categories:", error)
            return
        }
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }
        do {
            allTransactions = try await transactionsService.transactions(
                from: startOfDay,
                to: endOfDay
            )
            recalcDisplayedBalance()
        } catch {
            print("Failed to load transactions:", error)
        }
    }

    func applyManualBalance(_ newValue: Decimal) {
        manualStartBalance = newValue
        computedBalanceAtManual = computedBalanceFull
        displayedBalance = newValue
    }

    private func recalcDisplayedBalance() {
        if let manual = manualStartBalance {
            let delta = computedBalanceFull - computedBalanceAtManual
            displayedBalance = manual + delta
        } else {
            displayedBalance = computedBalanceFull
        }
    }
}


enum CurrencyData: String, CaseIterable, Identifiable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .rub: "Российский рубль"
        case .usd: "Американский доллар"
        case .eur: "Евро"
        }
    }
    
    var symbol: String {
        switch self {
        case .rub: "₽"
        case .usd: "$"
        case .eur: "€"
        }
    }
}
