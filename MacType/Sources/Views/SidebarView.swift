import SwiftUI

struct SidebarView: View {
    @Binding var selectedMode: TypingMode?

    var body: some View {
        List(TypingMode.allCases, id: \.id, selection: $selectedMode) { mode in
            Label(mode.title, systemImage: mode.icon)
                .tag(mode)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}