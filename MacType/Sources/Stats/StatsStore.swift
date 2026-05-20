import Foundation
import Combine

/// 統計資料管理（ObservableObject）
final class StatsStore: ObservableObject {
    @Published private(set) var sessions: [PracticeSessionRecord] = []

    private let store: FileStore
    private let sessionsKey = "sessions"

    init(store: FileStore = FileStore()) {
        self.store = store
        load()
    }

    // MARK: - Load / Persist

    private func load() {
        if let loaded: [PracticeSessionRecord] = store.load([PracticeSessionRecord].self) {
            sessions = loaded
        }
    }

    private func persist() {
        store.save(sessions)
    }

    // MARK: - Record Sessions

    /// 記錄英文練習結果
    func recordEnglish(result: PracticeResult, startTime: Date, endTime: Date) {
        let record = PracticeSessionRecord.fromEnglish(result: result, startTime: startTime, endTime: endTime)
        addSession(record)
    }

    /// 記錄弱指練習結果
    func recordWeakFinger(result: WeakFingerResult, startTime: Date, endTime: Date) {
        let record = PracticeSessionRecord.fromWeakFinger(result: result, startTime: startTime, endTime: endTime)
        addSession(record)
    }

    /// 記錄注音練習結果
    func recordZhuyin(result: ZhuyinPracticeResult, startTime: Date, endTime: Date) {
        let record = PracticeSessionRecord.fromZhuyin(result: result, startTime: startTime, endTime: endTime)
        addSession(record)
    }

    /// 新增 session（通用）
    func addSession(_ session: PracticeSessionRecord) {
        sessions.append(session)
        persist()
    }

    // MARK: - Dashboard Summary

    var dashboardSummary: DashboardSummary {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { $0.date == today }

        if todaySessions.isEmpty {
            return .empty
        }

        let totalSeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }
        let avgAccuracy = todaySessions.reduce(0.0) { $0 + $1.accuracy } / Double(todaySessions.count)
        let totalErrors = todaySessions.reduce(0) { $0 + $1.errorCount }

        // Top error keys
        var errorKeyCounts: [String: Int] = [:]
        for session in todaySessions {
            for (key, count) in session.errorKeys {
                errorKeyCounts[key, default: 0] += count
            }
        }
        let topErrorKeys = errorKeyCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }

        // Weak finger weaknesses (unique weak targets)
        let weakTargets = todaySessions.compactMap { $0.weakFingerTarget }
        let weakFingerWeaknesses = Array(Set(weakTargets))

        // Recent sessions (last 5)
        let recent = Array(sessions.suffix(5))

        return DashboardSummary(
            todaySessionCount: todaySessions.count,
            todayTotalSeconds: totalSeconds,
            todayAvgAccuracy: avgAccuracy,
            todayTotalErrors: totalErrors,
            topErrorKeys: Array(topErrorKeys),
            weakFingerWeaknesses: weakFingerWeaknesses,
            recentSessions: recent
        )
    }

    // MARK: - Stats Summary

    var statsSummary: StatsSummary {
        if sessions.isEmpty {
            return .empty
        }

        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        let totalErrors = sessions.reduce(0) { $0 + $1.errorCount }
        let totalKeystrokes = sessions.reduce(0) { $0 + $1.totalKeystrokes }
        let avgAccuracy = sessions.reduce(0.0) { $0 + $1.accuracy } / Double(sessions.count)

        // Mode stats
        var modeStatsDict: [PracticeMode: (count: Int, seconds: Double, accuracySum: Double)] = [:]
        for session in sessions {
            var current = modeStatsDict[session.mode] ?? (count: 0, seconds: 0, accuracySum: 0)
            current.count += 1
            current.seconds += session.durationSeconds
            current.accuracySum += session.accuracy
            modeStatsDict[session.mode] = current
        }
        var modeStats: [PracticeMode: ModeStats] = [:]
        for (mode, data) in modeStatsDict {
            modeStats[mode] = ModeStats(
                mode: mode,
                sessionCount: data.count,
                totalSeconds: data.seconds,
                avgAccuracy: data.count > 0 ? data.accuracySum / Double(data.count) : 0
            )
        }

        // Top error keys
        var errorKeyCounts: [String: Int] = [:]
        for session in sessions {
            for (key, count) in session.errorKeys {
                errorKeyCounts[key, default: 0] += count
            }
        }
        let topErrorKeys = errorKeyCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }

        let recent = Array(sessions.suffix(10))

        return StatsSummary(
            totalSessions: sessions.count,
            totalSeconds: totalSeconds,
            totalErrors: totalErrors,
            totalKeystrokes: totalKeystrokes,
            avgAccuracy: avgAccuracy,
            modeStats: modeStats,
            topErrorKeys: Array(topErrorKeys),
            recentSessions: recent
        )
    }

    // MARK: - Reset (for tests)

    func reset() {
        sessions = []
        store.delete()
    }
}