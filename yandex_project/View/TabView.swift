import SwiftUI

enum Tab: Hashable {
    case expenses, income, check, articles, settings
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .expenses

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray.withAlphaComponent(0.6)
        let app = UITabBarAppearance()
        app.configureWithOpaqueBackground()
        app.backgroundColor = .white
        app.stackedLayoutAppearance.selected.iconColor = UIColor(named: "Color")
        app.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "Color")!]
        app.stackedLayoutAppearance.normal.iconColor = UIColor.gray.withAlphaComponent(0.6)
        app.stackedLayoutAppearance.normal.titleTextAttributes =  [.foregroundColor: UIColor.gray.withAlphaComponent(0.6)]
        UITabBar.appearance().standardAppearance = app
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = app
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                TransactionsListView(direction: .outcome)
            }
            .tabItem {
                Image(systemName: "chart.line.downtrend.xyaxis")
                Text("Расходы")
            }
            .tag(Tab.expenses)
            NavigationView {
                TransactionsListView(direction: .income)
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Доходы")
            }
            .tag(Tab.income)
            CheckView()
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
    }
}

#Preview {
    MainTabView()
}

