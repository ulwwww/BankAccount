//
//  Transaction.swift
//  yandex_project
//
//  Created by ulwww on 26.06.25.
//
import Foundation
import SwiftUI


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
            .filter {
                incomeMap[$0.categoryId] == true
            }
            .map(\.amount)
            .reduce(0, +)
        let outcomeSum = allTransactions
            .filter {
                incomeMap[$0.categoryId] == false
            }
            .map(\.amount)
            .reduce(0, +)
        return incomeSum - outcomeSum
    }

    private let service = TransactionsService()
    private let calendar = Calendar.current

    init() {
        Task { await loadData() }
    }

    @MainActor
    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let cats = service.categories
        emojiMap  = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, String($0.emoji)) })
        incomeMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.isIncome == .income) })

        let startOfDay = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        do {
            allTransactions = try await service.takeTransaction(from: startOfDay, to: tomorrow)
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
