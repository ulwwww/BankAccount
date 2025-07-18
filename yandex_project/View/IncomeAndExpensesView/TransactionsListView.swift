//
//  TransactionListView.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.
//
import SwiftUI

enum DataError: Error {
    case invalidDate
}

struct TransactionsListView: View {
    @State private var isLoading = false
    let direction: Direction
    private let service = TransactionsService()
    private let calendar = Calendar.current
    @State private var transactions: [Transaction] = []
    @State private var emojiMap: [Int: String] = [:]
    @State private var categoryMap: [Int: String] = [:]
    @State private var isPresentingNew = false
    @State private var editingTx: Transaction?

    private var totalSum: Decimal {
        transactions.map { $0.amount }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .trailing) {
                    NavigationLink(destination: MyStoryView(direction: direction)) {
                        Image(systemName: Utility.Icons.history)
                            .font(.system(size: 25, weight: .light))
                            .foregroundColor(Utility.Colors.accent)
                            .frame(width: 44, height: 44)
                    }
                    .clipShape(Circle())
                    .padding(.horizontal, 16)

                    HStack {
                        Text(direction.titleToday)
                            .font(.largeTitle).bold()
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    HStack {
                        Text("Всего")
                        Spacer()
                        Text(NSDecimalNumber(decimal: totalSum), formatter: Utility.currency)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                    ScrollView {
                        Text("ОПЕРАЦИИ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 35)
                            .padding(.top, 16)

                        VStack(spacing: 0) {
                            ForEach(transactions) { transaction in
                                Button {
                                    editingTx = transaction
                                } label: {
                                    TransactionRow(
                                        categoryName: categoryMap[transaction.categoryId] ?? "",
                                        comment: transaction.comment,
                                        amount: transaction.amount,
                                        emoji: emojiMap[transaction.categoryId] ?? ""
                                    )
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)

                                if transaction.id != transactions.last?.id {
                                    Divider()
                                        .padding(.leading, 35)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .refreshable {
                        try? await loadData()
                    }
                    .task(id: direction) {
                        try? await loadData()
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isPresentingNew = true
                        } label: {
                            Image(systemName: Utility.Icons.plus)
                                .font(.system(size: 25, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                        }
                        .background(Color("Color"))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(Utility.Colors.background)
            .fullScreenCover(isPresented: $isPresentingNew) {
                EditingOperationView(
                    direction: direction,
                    onSave: { newTx in
                        transactions.append(newTx)
                    },
                    onDelete: {}
                )
                .ignoresSafeArea()
            }
            .fullScreenCover(item: $editingTx) { tx in
                EditingOperationView(
                    direction: direction,
                    transaction: tx,
                    onSave: { updatedTx in
                        if let index = transactions.firstIndex(where: { $0.id == updatedTx.id }) {
                            transactions[index] = updatedTx
                        }
                    },
                    onDelete: {
                        transactions.removeAll { $0.id == tx.id }
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    @MainActor
    private func loadData() async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let cats = service.categories
        emojiMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, String($0.emoji)) })
        categoryMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })

        let startOfDay = calendar.startOfDay(for: Date())
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataError.invalidDate
        }
        let all = try await service.takeTransaction(from: startOfDay, to: startOfTomorrow)
        let incomeMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.isIncome) })
        transactions = all.filter { tx in
            guard let isIncome = incomeMap[tx.categoryId] else { return false }
            return direction == .income ? isIncome == .income : isIncome == .outcome
        }
    }
}

private struct TransactionRow: View {
    let categoryName: String
    let comment: String
    let amount: Decimal
    let emoji: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Utility.Colors.iconBackground)
                    .frame(width: 30, height: 30)
                Text(emoji)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(NSDecimalNumber(decimal: amount), formatter: Utility.currency)
                .font(.body)
                .foregroundColor(.primary)
            Image(systemName: Utility.Icons.chevron)
                .foregroundColor(.secondary)
        }
    }
}

extension Direction {
    var titleToday: String {
        switch self {
        case .income: return "Доходы сегодня"
        case .outcome: return "Расходы сегодня"
        }
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TransactionsListView(direction: .outcome)
            TransactionsListView(direction: .income)
        }
    }
}
