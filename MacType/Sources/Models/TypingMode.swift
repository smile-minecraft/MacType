import SwiftUI

enum TypingMode: String, Identifiable, CaseIterable {
    case dashboard
    case english
    case weakFinger
    case zhuyin
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .english: return "English Practice"
        case .weakFinger: return "Weak Finger Practice"
        case .zhuyin: return "Zhuyin Key Practice"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .english: return "character.cursor.ibeam"
        case .weakFinger: return "hand.raised.fill"
        case .zhuyin: return "keyboard.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gear"
        }
    }
}