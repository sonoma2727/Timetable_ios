import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max")
                }
                .tag(0)

            WeekView()
                .tabItem {
                    Label("课表", systemImage: "calendar")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .onChange(of: model.requestedTab) { value in
            if let value = value {
                tab = value
                model.requestedTab = nil
            }
        }
    }
}
