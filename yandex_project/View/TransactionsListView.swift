//
//  TransactionListView.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.
//
import SwiftUI

private enum Constant {
    static let sectionSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let leadingIndent: CGFloat = 35
    static let topPadding: CGFloat = 0
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 4
    static let iconSize: CGFloat = 25
    static let buttonFrame: CGFloat = 44
    static let addIconSize: CGFloat = 25
    static let addButtonSize: CGFloat = 60
    static let iconContainer: CGFloat = 30
    static let emojiSize: CGFloat = 20
    static let iconSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 4
    static let rowVertical: CGFloat = 12
    static let sectionPadding: CGFloat = 16
}

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

    private var totalSum: Decimal {
        transactions.map({ $0.amount }).reduce(0, +)
    }

    var body: some View {
        ZStack {
            content
            addButton
        }
        .background(Utility.Colors.background)
    }

    private var content: some View {
        VStack(alignment: .trailing) {
            historyLink
            titleSection
            totalSection
            operationsList
        }
    }

    private var historyLink: some View {
        NavigationLink(destination: MyStoryView(direction: direction)) {
            Image(systemName: Utility.Icons.history)
                .font(.system(size: Constant.iconSize, weight: .light))
                .foregroundColor(Utility.Colors.accent)
                .frame(width: Constant.buttonFrame, height: Constant.buttonFrame)
        }
        .clipShape(Circle())
        .padding(.top, Constant.topPadding)
        .padding(.horizontal, Constant.horizontalPadding)
    }

    private var titleSection: some View {
        HStack {
            Text(direction.titleToday)
                .font(.largeTitle).bold()
            Spacer()
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.top, Constant.sectionSpacing)
    }

    private var totalSection: some View {
        HStack {
            Text(Utility.Strings.total)
            Spacer()
            Text(NSDecimalNumber(decimal: totalSum), formatter: Utility.currency)
        }
        .padding(Constant.sectionPadding)
        .background(Color.white)
        .cornerRadius(Constant.cornerRadius)
        .padding(.horizontal, Constant.horizontalPadding)
    }

    private var operationsList: some View {
        ScrollView {
            Text(Utility.Strings.operations)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Constant.leadingIndent)
                .padding(.top, Constant.sectionSpacing)

            VStack(spacing: 0) {
                ForEach(transactions) { tx in
                    TransactionRow(tx: tx, emoji: emojiMap[tx.categoryId] ?? "")
                        .padding(.horizontal)
                        .padding(.vertical, Constant.rowVertical)
                    if tx.id != transactions.last?.id {
                        Divider().padding(.leading, Constant.leadingIndent)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(Constant.cornerRadius)
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.bottom, Constant.sectionSpacing)
        }
        .refreshable {
            try? await loadData()
        }
        .task(id: direction) {
            try? await loadData()
        }
    }

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: Utility.Icons.plus)
                        .font(.system(size: Constant.addIconSize, weight: .light))
                        .foregroundColor(.white)
                        .frame(width: Constant.addButtonSize, height: Constant.addButtonSize)
                }
                .background(Color("Color"))
                .clipShape(Circle())
                .shadow(radius: Constant.shadowRadius)
                .padding(.trailing, Constant.horizontalPadding)
                .padding(.bottom, Constant.sectionSpacing)
            }
        }
    }

    @MainActor
    private func loadData() async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        emojiMap = Dictionary(
            uniqueKeysWithValues: service.categories.map { ($0.id, String($0.emoji)) }
        )
        let startOfDay = calendar.startOfDay(for: Date())
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataError.invalidDate
        }
        let all = try await service.takeTransaction(from: startOfDay, to: startOfTomorrow)
        let incomeMap = Dictionary(
            uniqueKeysWithValues: service.categories.map { ($0.id, $0.isIncome) }
        )
        transactions = all.filter { tx in
            guard let isIncome = incomeMap[tx.categoryId] else {
                return false
            }
            return direction == .income ? isIncome == .income : isIncome == .outcome
        }
    }
}

private struct TransactionRow: View {
    let tx: Transaction
    let emoji: String

    var body: some View {
        HStack(spacing: Constant.iconSpacing) {
            ZStack {
                Circle()
                    .fill(Utility.Colors.iconBackground)
                    .frame(width: Constant.iconContainer, height: Constant.iconContainer)
                Text(emoji)
                    .font(.system(size: Constant.emojiSize))
            }
            VStack(alignment: .leading, spacing: Constant.textSpacing) {
                Text(tx.comment)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            Spacer()
            Text(NSDecimalNumber(decimal: tx.amount), formatter: Utility.currency)
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
        case .income:  return "Доходы сегодня"
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

