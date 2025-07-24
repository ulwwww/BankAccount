//
//  ArticlesView.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.
//
import SwiftUI

struct ArticlesView: View {
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    @State private var categories: [Category] = []
    @State private var emojiMap: [Int: String] = [:]
    @State private var searchText: String = ""
    
    init() {
        let client = NetworkClient(
            baseURL: URL(string: "https://shmr-finance.ru/api/v1/")!,
            token: "NAMSSUiLh9AGS534c5Rxlwww"
        )
        self.transactionsService = TransactionsService(networkClient: client)
        self.categoriesService = CategoriesService(networkClient: client)
    }

    private func partOfWord(_ query: String, _ text: String) -> Bool {
        var idx = text.lowercased().startIndex
        for c in query.lowercased() {
            guard let found = text.lowercased()[idx...].firstIndex(of: c) else {
                return false
            }
            idx = text.lowercased().index(after: found)
        }
        return true
    }

    private var fuzzySearch: [Category] {
        let maxFuzzy = 2
        let query = searchText
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return categories
        }
        return categories.filter { c in
            return partOfWord(query, c.name.lowercased()) || levenshtein(query, c.name.lowercased()) <= maxFuzzy
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
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search")
        }
        .task {
            await loadData()
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
                    Divider().padding(.leading, 35)
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

    private func loadData() async {
        do {
            let fetched = try await categoriesService.categories()
            await MainActor.run {
                categories = fetched
                emojiMap = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, String($0.emoji)) })
            }
        } catch {
            print("Failed to load categories:", error)
            return
        }
    }
    
    private func levenshtein(_ s: String, _ t: String) -> Int {
        let s1 = Array(s.lowercased())
        let s2 = Array(t.lowercased())
        let m = s1.count, n = s2.count
        var dp = Array(repeating: Array(repeating: 0, count: n+1), count: m+1)
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }
        for i in 1...m {
            for j in 1...n {
                if s1[i-1] == s2[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j]+1, dp[i][j-1]+1, dp[i-1][j-1]+1)
                }
            }
        }
        return dp[m][n]
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
}

