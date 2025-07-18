//
//  MyStoryView.swift
//  yandex_project
//
//  Created by ulwww on 24.06.25.
//
import SwiftUI

struct MyStoryView: View {
    @StateObject private var viewModel: MyStoryViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var isShowingAnalysis = false

    init(direction: Direction) {
        _viewModel = StateObject(wrappedValue: MyStoryViewModel(direction: direction, accountId: 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            dateRangeSection
            operationsList
        }
        .background(Utility.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            leadingToolbarItem
            trailingToolbarItem
        }
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .refreshable { await viewModel.loadData() }
    }

    private var header: some View {
        Text("Моя история")
            .font(.largeTitle).bold()
            .padding(.horizontal)
            .padding(.top)
    }

    private var dateRangeSection: some View {
        VStack(spacing: 0) {
            dateRow(title: "Начало", date: $viewModel.startDate, onChange: viewModel.updateStartDate(to:))
            Divider()
            dateRow(title: "Конец", date: $viewModel.endDate, onChange: viewModel.updateEndDate(to:))
            Divider()
            totalRow
        }
        .tint(.green)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dateRow(title: String,date: Binding<Date>,onChange: @escaping (Date) -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("", selection: date, in: ...Date(), displayedComponents: .date)
            .datePickerStyle(.compact)
            .labelsHidden()
            .background(Color("Color"))
            .cornerRadius(7)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .onChange(of: date.wrappedValue, perform: onChange)
    }

    private var totalRow: some View {
        HStack {
            Text("Всего")
            Spacer()
            Text(
                NSDecimalNumber(decimal: viewModel.totalSum),
                formatter: Utility.currency
            )
        }
        .padding(12)
    }

    private var operationsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                operationsHeader
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.sortedTransactions) { tx in
                        OperationRow(tx: tx, emoji: viewModel.emojiMap[tx.categoryId] ?? "")
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        if tx.id != viewModel.sortedTransactions.last?.id {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private var operationsHeader: some View {
        HStack {
            Text("ОПЕРАЦИИ")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Menu {
                ForEach(MyStoryViewModel.SortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if viewModel.sortOption == option {
                                Image(systemName: Utility.Icons.checkmark)
                            }
                        }
                    }
                }
            } label: {
                Label("Сортировка", systemImage: Utility.Icons.sort)
                    .font(.subheadline)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .foregroundColor(Utility.Colors.accent)
                    .background(Utility.Colors.accent.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: Utility.Icons.back)
                    Text("Назад")
                }
                .foregroundColor(Utility.Colors.accent)
            }
        }
    }

    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(isActive: $isShowingAnalysis) {
                AnalysisViewControllerRepresentable(isPresented: $isShowingAnalysis, direction: viewModel.direction)
            } label: {
                Image(systemName: Utility.Icons.export)
                    .foregroundColor(Utility.Colors.accent)
            }
        }
    }
}

private struct OperationRow: View {
    let tx: Transaction
    let emoji: String
    private let timeFormat: Date.FormatStyle = .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Utility.Colors.iconBackground)
                    .frame(width: 30, height: 30)
                Text(emoji)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.comment)
                    .font(.body)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
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

struct AnalysisViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
        let direction: Direction

        func makeUIViewController(context: Context) -> AnalysisViewController {
            let vc = AnalysisViewController(direction: direction)
            vc.onBack = { self.isPresented = false }
            return vc
        }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

