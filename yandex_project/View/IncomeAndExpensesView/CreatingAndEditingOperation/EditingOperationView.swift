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
    let direction: Direction
    private let originalTransaction: Transaction?
    private let onSave: (Transaction) -> Void
    private let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []
    @State private var selectedCategory: Category?
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var comment: String = ""
    @State private var mainAccount: BankAccount?
    @State private var showAlert: Bool = false

    private let service = TransactionsService()
    private let bankAccountsService = BankAccountsService()

    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
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
        _date = State(initialValue: transaction?.transactionDate ?? Date())
        let initialAmount = transaction.map { tx in
            var str = "\(tx.amount)"
            if let sep = Locale.current.decimalSeparator, sep != "." {
                str = str.replacingOccurrences(of: ".", with: sep)
            }
            return str
        } ?? ""
        _amountText = State(initialValue: initialAmount)
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
            .toolbar {
                toolbarItems
            }
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
        .padding().background(Color.white)
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
        .padding().background(Color.white)
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
        .padding().background(Color.white).tint(Utility.Colors.accent)
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
        .padding().background(Color.white)
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Комментарий")
            TextField("Введите комментарий", text: $comment)
                .disableAutocorrection(true)
        }
        .padding().background(Color.white)
    }

    private var deleteSection: some View {
        Group {
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
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") { dismiss() }
                    .foregroundColor(Utility.Colors.accent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(originalTransaction == nil ? "Создать" : "Сохранить") {
                    if isFormValid { Task { await saveOperation() } }
                    else { showAlert = true }
                }
                .foregroundColor(Utility.Colors.accent)
            }
        }
    }

    private func filterAmount(_ new: String) {
        let filtered = new.filter { c in c.isWholeNumber || String(c) == decimalSeparator }
        let parts = filtered.components(separatedBy: decimalSeparator)
        let result = parts.count > 2 ? parts[0] + decimalSeparator + parts[1] : filtered
        if result != new { amountText = result }
    }

    private var isFormValid: Bool {
        selectedCategory != nil
            && Decimal(string: amountText.replacingOccurrences(of: decimalSeparator, with: ".")) != nil
            && !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadInitialData() async {
        do {
            categories = service.categories
            mainAccount = try await bankAccountsService.getAccount()
            if let tx = originalTransaction {
                selectedCategory = categories.first(where: { $0.id == tx.categoryId })
            }
        } catch {
            print("Ошибка при загрузке данных: \(error)")
        }
    }

    private func saveOperation() async {
        guard let account = mainAccount, let category = selectedCategory, let amount = Decimal(string: amountText.replacingOccurrences(of: decimalSeparator, with: ".")) else {
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
                tx = try await service.createTransaction(tx)
            } else {
                tx = try await service.editTransaction(tx)
            }
            onSave(tx)
            dismiss()
        } catch {
            fatalError("save error \(error)")
        }
    }

    private func deleteOperation() async {
        guard let tx = originalTransaction else { return }
        do {
            try await service.removeTransaction(tx.id)
            onDelete()
            dismiss()
        } catch {
            fatalError("edit error \(error)")
        }
    }
}

#Preview {
    EditingOperationView(direction: .income, onSave: { _ in }, onDelete: {})
}
