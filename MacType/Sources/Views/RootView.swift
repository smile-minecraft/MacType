import SwiftUI

struct RootView: View {
    @State private var selectedMode: TypingMode? = .dashboard
    @EnvironmentObject var statsStore: StatsStore

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedMode: $selectedMode)
        } detail: {
            DetailView(selectedMode: selectedMode)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct DetailView: View {
    let selectedMode: TypingMode?

    var body: some View {
        Group {
            switch selectedMode {
            case .dashboard:
                DashboardView()
            case .english:
                EnglishPracticeView()
            case .weakFinger:
                WeakFingerPracticeView()
            case .zhuyin:
                ZhuyinKeyPracticeView()
            case .stats:
                StatsView()
            case .settings:
                SettingsView()
            case nil:
                DashboardView()
            }
        }
    }
}