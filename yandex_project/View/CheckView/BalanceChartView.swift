//
//  BalanceChartView.swift
//  yandex_project
//
//  Created by ulwww on 25.07.25.
//

import SwiftUI
import Charts

struct BalanceData: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

struct BalanceChartView: View {
    @ObservedObject var vm: MyStoryViewModel
    @Binding var isEditing: Bool
    @State private var data: [BalanceData] = []
    private let calendar = Calendar.current
    private var dayFormatter: DateFormatter {
        let fm = DateFormatter()
        fm.dateFormat = "dd.MM"
        return fm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isEditing {
                chartView
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: loadDailyDataForCurrentMonth)
    }

    private var chartView: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Дата", item.date),
                    y: .value("Сумма", Double(truncating: item.amount as NSNumber))
                )
                .foregroundStyle(.red)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            let nonZeroDates = data
                .filter { $0.amount != 0 }
                .map    { $0.date }

            AxisMarks(values: nonZeroDates) { value in
                AxisTick()
                AxisValueLabel() {
                    if let date = value.as(Date.self) {
                        Text(dayFormatter.string(from: date))
                    }
                }
            }
        }
        
        .chartYAxis(.hidden)
        .frame(height: 200)
    }

    private func loadDailyDataForCurrentMonth() {
        let txs = vm.transactions
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: comps)!
        let dayCount = calendar.range(of: .day, in: .month, for: now)!.count
        let sumsByDay = Dictionary(
            grouping: txs,
            by: { calendar.startOfDay(for: $0.transactionDate) }
        ).mapValues { arr in
            arr.reduce(Decimal(0)) { $0 + $1.amount }
        }
        data = (0..<dayCount).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
            let amt = sumsByDay[date] ?? 0
            return BalanceData(date: date, amount: amt)
        }
    }
}

