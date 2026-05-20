import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var statsStore: StatsStore

    private var summary: DashboardSummary {
        statsStore.dashboardSummary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("MacType")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("今日練習概覽")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

                Divider()

                if summary.todaySessionCount == 0 {
                    emptyState
                } else {
                    todayStatsGrid
                    topErrorKeysSection
                    weakFingerWeaknessesSection
                    recentSessionsSection
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("尚無練習記錄")
                .font(.headline)
            Text("開始一個練習模式來記錄你的學習進度")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }

    private var todayStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "今日練習次數", value: "\(summary.todaySessionCount)", icon: "number")
            statCard(title: "總練習時間", value: formatDuration(summary.todayTotalSeconds), icon: "clock")
            statCard(title: "平均正確率", value: String(format: "%.1f%%", summary.todayAvgAccuracy), icon: "percent")
            statCard(title: "總錯誤次數", value: "\(summary.todayTotalErrors)", icon: "xmark.circle")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    private var topErrorKeysSection: some View {
        Group {
            if !summary.topErrorKeys.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("最常錯誤鍵")
                        .font(.headline)
                    ForEach(summary.topErrorKeys.prefix(5), id: \.key) { item in
                        HStack {
                            Text("'\(item.key)'")
                                .fontWeight(.semibold)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("\(item.count) 次")
                                .foregroundStyle(.secondary)
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

    private var weakFingerWeaknessesSection: some View {
        Group {
            if !summary.weakFingerWeaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("弱指訓練重點")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(summary.weakFingerWeaknesses, id: \.self) { target in
                            Text(target)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    private var recentSessionsSection: some View {
        Group {
            if !summary.recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近練習")
                        .font(.headline)
                    ForEach(summary.recentSessions.suffix(5).reversed()) { session in
                        HStack {
                            Circle()
                                .fill(colorForMode(session.mode))
                                .frame(width: 8, height: 8)
                            Text(session.mode.displayName)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", session.accuracy))
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Text(formatDuration(session.durationSeconds))
                                .foregroundStyle(.tertiary)
                                .font(.caption)
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

    private func colorForMode(_ mode: PracticeMode) -> Color {
        switch mode {
        case .english: return .blue
        case .weakFinger: return .orange
        case .zhuyin: return .green
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}