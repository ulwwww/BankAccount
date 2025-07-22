//
//  TransactionRow.swift
//  yandex_project
//
//  Created by ulwww on 22.07.25.
//
import SwiftUI
import Foundation

struct TransactionRow: View {
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
