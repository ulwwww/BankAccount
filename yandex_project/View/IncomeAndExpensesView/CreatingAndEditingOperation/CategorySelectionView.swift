//
//  CategorySelectionView.swift
//  yandex_project
//
//  Created by ulwww on 11.07.25.
//
import SwiftUI

struct CategorySelectionView: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(categories, id: \.id) { category in
            HStack {
                Text(category.name)
                Spacer()
                if category.id == selected?.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selected = category
                dismiss()
            }
        }
        .navigationTitle("Выберите статью")
    }
}
