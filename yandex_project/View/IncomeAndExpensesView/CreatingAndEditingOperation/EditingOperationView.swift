//
// EditingOperationView.swift
// yandex_project
//
// Created by ulwww on 9.07.25.
//

import SwiftUI

extension Direction {
    var title: String {
        switch self {
        case .income: return "Мои Доходы"
        case .outcome: return "Мои Расходы"
        }
    }
}

struct EditingOperationView: View {
    private let direction: Direction
    private let originalTransaction: Transaction?
    private let onSave: (Transaction) -> Void
    private let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let networkClient: NetworkClient
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    private let bankAccountsService: BankAccountsService

    @State private var categories: [Category] = []
    @State private var selectedCategory: Category?
    @State private var amountText: String
    @State private var date: Date
    @State private var comment: String
    @State private var mainAccount: BankAccount?
    @State private var showAlert = false

    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }

    private var isFormValid: Bool {
        selectedCategory != nil
            && Decimal(string: amountText.replacingOccurrences(of: decimalSeparator, with: ".")) != nil
            && !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && mainAccount != nil
    }

    init(
        direction: Direction,
        transaction: Transaction? = nil,
        onSave: @escaping (Transaction) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.direction = direction
        self.originalTransaction = transaction
        self.onSave = onSave
        self.onDelete = onDelete

        let client = NetworkClient(
            baseURL: URL(string: "https://shmr-finance.ru/api/v1/")!,
            token: "NAMSSUiLh9AGS534c5Rxlwww"
        )
        self.networkClient = client
        self.transactionsService = TransactionsService(networkClient: client)
        self.categoriesService = CategoriesService(networkClient: client)
        self.bankAccountsService = BankAccountsService(networkClient: client)

        _date = State(initialValue: transaction?.transactionDate ?? Date())
        let initialAmountString: String = {
            guard let tx = transaction else { return "" }
            var s = "\(tx.amount)"
            if let sep = Locale.current.decimalSeparator, sep != "." {
                s = s.replacingOccurrences(of: ".", with: sep)
            }
            return s
        }()
        _amountText = State(initialValue: initialAmountString)
        _comment = State(initialValue: transaction?.comment ?? "")
        _selectedCategory = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    categorySection
                    Divider()
                    amountSection
                    Divider()
                    dateSection
                    Divider()
                    timeSection
                    Divider()
                    commentSection
                    Spacer().frame(height: 20)
                    deleteSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(direction.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .alert("Пожалуйста, заполните все поля", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
            .task { await loadInitialData() }
        }
    }

    private var categorySection: some View {
        HStack {
            Text("Статья")
            Spacer()
            NavigationLink(
                destination: CategorySelectionView(categories: categories, selected: $selectedCategory)
            ) {
                Text(selectedCategory?.name ?? "Выбрать")
                    .foregroundColor(selectedCategory == nil ? .gray : .primary)
            }
        }
        .padding()
        .background(Color.white)
    }

    private var amountSection: some View {
        HStack {
            Text("Сумма")
            Spacer()
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: amountText, perform: filterAmount)
        }
        .padding()
        .background(Color.white)
    }

    private var dateSection: some View {
        HStack {
            Text("Дата")
            Spacer()
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .background(Color("Color"))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .tint(Utility.Colors.accent)
    }

    private var timeSection: some View {
        HStack {
            Text("Время")
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .background(Color("Color"))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Комментарий")
            TextField("Введите комментарий", text: $comment)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white)
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        if originalTransaction != nil {
            Divider()
            Button(role: .destructive) {
                Task { await deleteOperation() }
            } label: {
                Text(direction == .income ? "Удалить доход" : "Удалить расход")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") { dismiss() }
                    .foregroundColor(Utility.Colors.accent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(originalTransaction == nil ? "Создать" : "Сохранить") {
                    if isFormValid {
                        Task { await saveOperation() }
                    } else {
                        showAlert = true
                    }
                }
                .foregroundColor(Utility.Colors.accent)
            }
        }
    }

    private func filterAmount(_ new: String) {
        let filtered = new.filter { $0.isWholeNumber || String($0) == decimalSeparator }
        let parts = filtered.components(separatedBy: decimalSeparator)
        let result = parts.count > 2
            ? parts[0] + decimalSeparator + parts[1]
            : filtered
        if result != new { amountText = result }
    }

    private func loadInitialData() async {
        do {
            let fetchedCats = try await categoriesService.categories()
            let fetchedAccounts = try await bankAccountsService.getAllAccounts()
            await MainActor.run {
                self.categories = fetchedCats
                if let tx = originalTransaction {
                    self.selectedCategory = fetchedCats.first { $0.id == tx.categoryId }
                }
                self.mainAccount = fetchedAccounts.first {
                    $0.id == originalTransaction?.accountId
                } ?? fetchedAccounts.first
            }
        } catch {
            print("error loading data: ", error)
        }
    }

    private func saveOperation() async {
        guard
            let account = mainAccount,
            let category = selectedCategory,
            let amount = Decimal(string: amountText.replacingOccurrences(of: decimalSeparator, with: "."))
        else {
            return
        }

        let now = Date()
        var tx = Transaction(
            id: originalTransaction?.id ?? UUID().hashValue,
            accountId: account.id,
            categoryId: category.id,
            amount: amount,
            comment: comment,
            transactionDate: date,
            createdAt: originalTransaction?.createdAt ?? now,
            updatedAt: now
        )

        do {
            if originalTransaction == nil {
                tx = try await transactionsService.createTransaction(tx)
            } else {
                tx = try await transactionsService.updateTransaction(tx)
            }
            onSave(tx)
            dismiss()
        } catch {
            print("error in transaction: ", error)
        }
    }

    private func deleteOperation() async {
        guard let tx = originalTransaction else { return }
        do {
            try await transactionsService.deleteTransaction(id: tx.id)
            onDelete()
            dismiss()
        } catch {
            print("error in delete transaction: ", error)
        }
    }
}

struct EditingOperationView_Previews: PreviewProvider {
    static var previews: some View {
        EditingOperationView(direction: .income, onSave: { _ in }, onDelete: {})
    }
}
