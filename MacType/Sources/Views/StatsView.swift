import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsStore: StatsStore

    private var summary: StatsSummary {
        statsStore.statsSummary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("統計")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("學習進度總覽")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

                Divider()

                if summary.totalSessions == 0 {
                    emptyState
                } else {
                    overallStatsGrid
                    modeBreakdownSection
                    topErrorKeysSection
                    recentSessionsSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("尚無統計資料")
                .font(.headline)
            Text("完成練習後這裡會顯示你的學習統計")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }

    private var overallStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "總練習次數", value: "\(summary.totalSessions)", icon: "number")
            statCard(title: "總練習時間", value: formatDuration(summary.totalSeconds), icon: "clock")
            statCard(title: "總錯誤次數", value: "\(summary.totalErrors)", icon: "xmark.circle")
            statCard(title: "總擊鍵數", value: "\(summary.totalKeystrokes)", icon: "character.cursor.ibeam")
            statCard(title: "平均正確率", value: String(format: "%.1f%%", summary.avgAccuracy), icon: "percent")
            statCard(title: "總正確擊鍵", value: "\(summary.totalKeystrokes - summary.totalErrors)", icon: "checkmark.circle")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    private var modeBreakdownSection: some View {
        Group {
            if !summary.modeStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("各模式統計")
                        .font(.headline)

                    ForEach(PracticeMode.allCases, id: \.self) { mode in
                        if let stats = summary.modeStats[mode] {
                            modeStatRow(mode: mode, stats: stats)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
            }
        }
    }

    private func modeStatRow(mode: PracticeMode, stats: ModeStats) -> some View {
        HStack {
            Circle()
                .fill(colorForMode(mode))
                .frame(width: 8, height: 8)
            Text(mode.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text("\(stats.sessionCount) 次")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(formatDuration(stats.totalSeconds))
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(String(format: "%.1f%%", stats.avgAccuracy))
                .fontWeight(.semibold)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private var topErrorKeysSection: some View {
        Group {
            if !summary.topErrorKeys.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("錯誤鍵排行榜")
                        .font(.headline)
                    ForEach(Array(summary.topErrorKeys.prefix(10).enumerated()), id: \.element.key) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .frame(width: 20)
                            Text("'\(item.key)'")
                                .fontWeight(.semibold)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("\(item.count) 次")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    private var recentSessionsSection: some View {
        Group {
            if !summary.recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近練習記錄")
                        .font(.headline)

                    ForEach(summary.recentSessions.suffix(10).reversed()) { session in
                        HStack {
                            Text(formattedDate(session.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Circle()
                                .fill(colorForMode(session.mode))
                                .frame(width: 6, height: 6)
                            Text(session.mode.displayName)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            Text(String(format: "%.0f%%", session.accuracy))
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Spacer()
                            Text(formatDuration(session.durationSeconds))
                                .foregroundStyle(.tertiary)
                                .font(.caption2)
                            if let wpm = session.wpm {
                                Text(String(format: "%.0f WPM", wpm))
                                    .foregroundStyle(.tertiary)
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.0f秒", seconds)
        } else if seconds < 3600 {
            let mins = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(mins)分\(secs)秒"
        } else {
            let hrs = Int(seconds / 3600)
            let mins = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hrs)小時\(mins)分"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private func colorForMode(_ mode: PracticeMode) -> Color {
        switch mode {
        case .english: return .blue
        case .weakFinger: return .orange
        case .zhuyin: return .green
        }
    }
}