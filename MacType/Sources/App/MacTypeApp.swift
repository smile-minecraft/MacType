import SwiftUI

@main
struct MacTypeApp: App {
    @StateObject private var statsStore = StatsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(statsStore)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
    }
}