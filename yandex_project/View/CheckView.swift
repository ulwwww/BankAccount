//
//  CheckView.swift
//  yandex_project
//
//  Created by ulwww on 26.06.25.
//
import SwiftUI
import UIKit
struct CheckView: View {
    @StateObject var vm: TransactionsListViewModel
    @FocusState private var isBalanceFlag: Bool
    @State private var isEditing: Bool = false
    @State private var draftBalance: String
    @State private var flagViewCurrency: Bool = false
    @State private var hiddenBalance: Bool = false

    init(vm: TransactionsListViewModel) {
        _vm = StateObject(wrappedValue: vm)
        _draftBalance = State(initialValue: vm.displayedBalance.description)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                content
                ShakeDetector {
                    hiddenBalance.toggle()
                }
                .allowsHitTesting(false)
            }
        }
        .background(Utility.Colors.background.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func currencySelectionDialog() -> some View {
        ForEach(CurrencyData.allCases) { curr in
            Button("\(curr.name) \(curr.symbol)") {
                vm.currency = curr
                draftBalance = vm.displayedBalance.description
            }
            .tint(Utility.Colors.accent)
        }
        Button("Отмена", role: .cancel) { }
            .tint(Color.red)
    }


    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                balanceCurrencySection
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await vm.loadData() }
        .navigationTitle("Мой счет")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleEdit) {
                    Text(isEditing ? "Сохранить" : "Редактировать")
                        .font(.headline)
                        .foregroundColor(Utility.Colors.accent)
                }
            }
        }
        .confirmationDialog("Валюта", isPresented: $flagViewCurrency, titleVisibility: .visible) {
            currencySelectionDialog()
        }
    }

    private var balanceCurrencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("💰")
                Text("Баланс").font(.headline)
                Spacer()
                if isEditing {
                    TextField("", text: $draftBalance)
                        .keyboardType(.asciiCapableNumberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.gray)
                        .focused($isBalanceFlag)
                        .onTapGesture { isBalanceFlag = true }
                        .submitLabel(.done)
                        .onChange(of: draftBalance) { new in
                            draftBalance = balanceEditor(new)
                        }
                } else {
                    Text(vm.displayedBalance.description)
                        .foregroundStyle(.gray)
                        .spoiler(isOn: hiddenBalance)
                }
            }
            .padding(.all, 16)
            .frame(maxWidth: .infinity)
            .background(isEditing ? Color.white : Color("Color"))
            .cornerRadius(12)

            HStack(spacing: 8) {
                Text("Валюта").font(.headline)
                Spacer()
                Text(vm.currency.symbol).foregroundStyle(.gray)
                if isEditing {
                    Image(systemName: Utility.Icons.chevron)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 16).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(isEditing ? Color.white : Utility.Colors.currencyBackground)
            .cornerRadius(12)
            .onTapGesture {
                if isEditing {
                    flagViewCurrency = true
                }
            }
        }
    }

    private func toggleEdit() {
        if isEditing {
            if let newVal = Decimal(string: draftBalance) {
                vm.applyManualBalance(newVal)
            }
            isBalanceFlag = false
        } else {
            draftBalance = vm.displayedBalance.description
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isBalanceFlag = true
            }
        }
        withAnimation {
            isEditing.toggle()
        }
    }

    private func balanceEditor(_ input: String) -> String {
        let val = input.filter { $0.isWholeNumber || $0 == "." }
        let parts  = val.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count <= 1 {
            return String(parts.joined())
        } else {
            return parts[0] + "." + parts[1]
        }
    }
}


#Preview {
    let vm = TransactionsListViewModel()
    CheckView(vm: vm)
}
