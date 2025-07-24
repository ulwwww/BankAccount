//
//  TransactionsListView.swift
//  yandex_project
//
import SwiftUI
import SwiftData

enum DataError: Error {
    case invalidDate
}

struct TransactionsListView: View {
    let direction: Direction
    private let networkClient: NetworkClient
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService

    @State private var isLoading = false
    @State private var transactions: [Transaction] = []
    @State private var emojiMap: [Int: String] = [:]
    @State private var categoryMap: [Int: String] = [:]
    @State private var isPresentingNew = false
    @State private var editingTx: Transaction?

    private let calendar = Calendar.current
    private var totalSum: Decimal {
        transactions.map(\.amount).reduce(0, +)
    }

    init(direction: Direction) {
        self.direction = direction
        let client = NetworkClient(
            baseURL: URL(string: "https://shmr-finance.ru/api/v1/")!,
            token: "NAMSSUiLh9AGS534c5Rxlwww"
        )
        self.networkClient = client
        self.transactionsService = TransactionsService(networkClient: client)
        self.categoriesService = CategoriesService(networkClient: client)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                content
                newButton
            }
            .background(Utility.Colors.background)
            .sheet(isPresented: $isPresentingNew) {
                EditingOperationView(
                    direction: direction,
                    onSave: { newTx in transactions.append(newTx) },
                    onDelete: {}
                )
                .ignoresSafeArea()
            }
            .sheet(item: $editingTx) { tx in
                EditingOperationView(
                    direction: direction,
                    transaction: tx,
                    onSave: { updatedTx in
                        if let idx = transactions.firstIndex(where: { $0.id == updatedTx.id }) {
                            transactions[idx] = updatedTx
                        }
                    },
                    onDelete: { transactions.removeAll { $0.id == tx.id } }
                )
                .ignoresSafeArea()
            }
            .task(id: direction) {
                await loadData()
            }
        }
    }

    private var content: some View {
        VStack(alignment: .trailing) {
            historyLink
            title
            totalView
            transactionList
        }
    }

    private var historyLink: some View {
        NavigationLink(destination: MyStoryView(direction: direction)) {
            Image(systemName: Utility.Icons.history)
                .font(.system(size: 25, weight: .light))
                .foregroundColor(Utility.Colors.accent)
                .frame(width: 44, height: 44)
        }
        .clipShape(Circle())
        .padding(.horizontal, 16)
    }

    private var title: some View {
        HStack {
            Text(direction.titleToday)
                .font(.largeTitle).bold()
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var totalView: some View {
        HStack {
            Text("Всего")
            Spacer()
            Text(NSDecimalNumber(decimal: totalSum), formatter: Utility.currency)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var transactionList: some View {
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
                        Divider().padding(.leading, 35)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            await loadData()
        }
    }

    private var newButton: some View {
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

    @MainActor
    private func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let cats = try await categoriesService.categories()
            let nameMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
            let emojiMapLocal = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, String($0.emoji)) })
            let typeMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.isIncome) })
            let startOfDay = calendar.startOfDay(for: Date())
            guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw DataError.invalidDate
            }
            let all = try await transactionsService.transactions(
                from: startOfDay,
                to: startOfTomorrow
            )
            let filtered = all.filter { tx in
                typeMap[tx.categoryId] == direction
            }
            await MainActor.run {
                categoryMap = nameMap
                emojiMap = emojiMapLocal
                transactions = filtered
            }
        } catch {
            print("loadData error:", error)
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
