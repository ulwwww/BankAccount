//
//  ArticlesView.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.
//
import SwiftUI
import Fuse

struct ArticlesView: View {
    private let service = TransactionsService()
    @State private var categories: [Category] = []
    @State private var emojiMap: [Int: String] = [:]
    @State private var searchText: String = ""
    private let fuse = Fuse()
    
    private var fuzzySearch: [Category] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return categories
        }
        let maxFuzzyScore: Double = 0.3
        return categories.compactMap { category in
            if let result = fuse.search(query, in: category.name), result.score <= maxFuzzyScore {
                return category
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                header
                listSection
            }
            .navigationTitle("Мои статьи")
            .navigationBarBackButtonHidden(true)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        }
        .task {
            loadData()
        }
    }

    private var header: some View {
        Text("СТАТЬИ")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 35)
            .padding(.top, 16)
    }

    private var listSection: some View {
        VStack(spacing: 0) {
            ForEach(fuzzySearch, id: \.id) { category in
                rowView(for: category)
                if category.id != fuzzySearch.last?.id {
                    Divider()
                        .padding(.leading, 35)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func rowView(for category: Category) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Utility.Colors.iconBackground)
                    .frame(width: 30, height: 30)
                Text(emojiMap[category.id] ?? "")
                    .font(.system(size: 20))
            }
            Text(category.name)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func loadData() {
        let c = service.categories
        emojiMap = Dictionary(uniqueKeysWithValues: c.map { ($0.id, String($0.emoji)) })
        categories = c
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
}
