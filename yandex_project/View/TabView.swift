import SwiftUI

enum Tab: Hashable {
    case expenses, income, check, articles, settings
}

struct MainTabView: View {
    @StateObject private var vm = TransactionsListViewModel()
    @State private var selectedTab: Tab = .expenses

    init() {
        let app = UITabBarAppearance()
        app.configureWithOpaqueBackground()
        app.backgroundColor = .white
        UITabBar.appearance().standardAppearance = app
        UITabBar.appearance().scrollEdgeAppearance = app
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionsListView(direction: .outcome)
                .tabItem {
                Image(systemName: "chart.line.downtrend.xyaxis")
                Text("Расходы")
            }
            .tag(Tab.expenses)
            TransactionsListView(direction: .income)
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Доходы")
            }
                .tag(Tab.income)
            CheckView(vm: vm)
                .accentColor(Utility.Colors.accent)
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Счет")
                }
                .tag(Tab.check)
            ArticlesView()
                .tabItem {
                    Image(systemName: "line.horizontal.3")
                    Text("Статьи")
                }
                .tag(Tab.articles)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Настройки")
                }
                .tag(Tab.settings)
        }
        .accentColor(Color("Color"))
        .toolbarBackground(Color.white, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}

