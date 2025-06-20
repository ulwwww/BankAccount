//
//  MyStoryView.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.
//
import SwiftUI

private enum Constants {
    static let sectionSpacing: CGFloat = 16
    static let rowVertical: CGFloat = 12
    static let rowPadding: CGFloat = 12
    static let iconSize: CGFloat = 30
    static let emojiSize: CGFloat = 20
    static let iconSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 4
    static let menuVert: CGFloat = 7
    static let menuHorz: CGFloat = 10
    static let menuSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let smallCorner: CGFloat = 8
    static let iconIndent: CGFloat = 64
}

struct MyStoryView: View {
    @State private var transactions = [Transaction]()
    @State private var emojiMap = [Int: String]()
    @State private var sortOption: SortOption = .date
    @State private var isLoading = false
    
    enum SortOption: CaseIterable, Identifiable {
        case date
        case amount

        var id: Self { self }
        var title: String {
            switch self {
            case .date: return Utility.Strings.sortByDate
            case .amount: return Utility.Strings.sortByAmount
            }
        }
    }

    let direction: Direction
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.calendar) private var calendar
    private let service = TransactionsService()
    @State private var startDate: Date
    @State private var endDate: Date

    private var totalSum: Decimal {
        transactions.map(\.amount).reduce(0, +)
    }

    private var sortedTransactions: [Transaction] {
        switch sortOption {
        case .date: return transactions.sorted { $0.createdAt > $1.createdAt }
        case .amount: return transactions.sorted { $0.amount > $1.amount }
        }
    }

    init(direction: Direction) {
        self.direction = direction
        let curCal = Calendar.current
        let monthAgo = curCal.date(byAdding: .month, value: -1, to: Date())!
        _startDate = State(initialValue: curCal.startOfDay(for: monthAgo))
        _endDate = State(initialValue: curCal.startOfDay(for: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            header
            periodSection
            operSection
        }
        .background(Utility.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: Utility.Icons.back)
                            Text(Utility.Strings.back)
                        }
                        .foregroundColor(Utility.Colors.accent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: Utility.Icons.export)
                            .foregroundColor(Utility.Colors.accent)
                    }
                }
            }
        .environment(\.locale, Locale(identifier: "ru_RU"))
    }

    private var header: some View {
        Text(Utility.Strings.history)
            .font(.largeTitle).bold()
            .padding(.horizontal)
            .padding(.top)
    }

    private var periodSection: some View {
        VStack(spacing: 0) {
            DatePickerRow(label: Utility.Strings.start, date: $startDate, range: ...Date())
                .onChange(of: startDate) { _, new in if new > endDate { endDate = new } }
            Divider()
            DatePickerRow(label: Utility.Strings.end, date: $endDate, range: ...Date())
                .onChange(of: endDate) { _, new in if new < startDate { startDate = new } }
            Divider()
            HStack {
                Text(Utility.Strings.total)
                Spacer()
                Text(NSDecimalNumber(decimal: totalSum), formatter: Utility.currency)
            }
            .padding(Constants.rowPadding)
        }
        .tint(.green)
        .background(Color(.systemBackground))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal)
    }

    private var operSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                operHeader
                LazyVStack(spacing: 0) {
                    ForEach(sortedTransactions) { tx in
                        OperationRow(tx: tx, emoji: emojiMap[tx.categoryId] ?? "")
                            .padding(.horizontal)
                            .padding(.vertical, Constants.rowVertical)
                        if tx.id != sortedTransactions.last?.id {
                            Divider().padding(.leading, Constants.iconIndent)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(Constants.cornerRadius)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .refreshable { try? await loadData() }
        .task(id: startDate) {
            try? await loadData()
        }
        .task(id: endDate) {
            try? await loadData()
        }
        .task(id: direction) {
            try? await loadData()
        }
    }

    private var operHeader: some View {
        HStack {
            Text(Utility.Strings.operations)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Menu {
                ForEach(SortOption.allCases) { option in
                    Button { sortOption = option } label: {
                        Label(option.title, systemImage: sortOption == option ? Utility.Icons.checkmark : "")
                    }
                }
            } label: {
                Label(Utility.Strings.sort, systemImage: Utility.Icons.sort)
                    .font(.subheadline)
                    .padding(.vertical, Constants.menuVert)
                    .padding(.horizontal, Constants.menuHorz)
                    .foregroundColor(Utility.Colors.accent)
                    .background(Utility.Colors.accent.opacity(0.1))
                    .cornerRadius(Constants.smallCorner)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Constants.menuSpacing)
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { presentationMode.wrappedValue.dismiss() } label: {
                    Label(Utility.Strings.back, systemImage: Utility.Icons.back)
                }
                .foregroundColor(Utility.Colors.accent)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: Utility.Icons.export)
                        .foregroundColor(Utility.Colors.accent)
                }
            }
        }
    }

    @MainActor
    private func loadData() async throws {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }

        let start = calendar.startOfDay(for: startDate)
        let endStart = calendar.startOfDay(for: endDate)
        let end = calendar.date(byAdding: DateComponents(hour:23, minute:59, second:59), to: endStart) ?? endStart

        let cats = service.categories
        emojiMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, String($0.emoji)) })
        let all = try await service.takeTransaction(from: start, to: end)
        let isIncomeMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.isIncome) })
        transactions = all.filter { tx in
            guard let dir = isIncomeMap[tx.categoryId] else { return false }
            return direction == .income ? dir == .income : dir == .outcome
        }
    }
}

private struct DatePickerRow: View {
    let label: String
    @Binding var date: Date
    let range: PartialRangeThrough<Date>
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            DatePicker("", selection: $date, in: range, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .padding(.vertical, Constants.rowVertical)
        .padding(.horizontal)
    }
}

private struct OperationRow: View {
    let tx: Transaction
    let emoji: String
    private let timeFormat: Date.FormatStyle = .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
    var body: some View {
        HStack(spacing: Constants.iconSpacing) {
            ZStack {
                Circle()
                    .fill(Utility.Colors.iconBackground)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                Text(emoji)
                    .font(.system(size: Constants.emojiSize))
            }
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(tx.comment).font(.body).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Constants.textSpacing) {
                Text(NSDecimalNumber(decimal: tx.amount), formatter: Utility.currency)
                Text(tx.createdAt, format: timeFormat)
            }
            Image(systemName: Utility.Icons.chevron)
                .foregroundColor(.secondary)
        }
    }
}

struct MyStoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                MyStoryView(direction: .income)
            }
            NavigationStack {
                MyStoryView(direction: .outcome)
            }
        }
    }
}


