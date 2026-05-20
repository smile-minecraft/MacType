import Foundation

/// 練習模式
enum PracticeMode: String, Codable, CaseIterable {
    case english
    case weakFinger
    case zhuyin

    var displayName: String {
        switch self {
        case .english: return "英文練習"
        case .weakFinger: return "弱指訓練"
        case .zhuyin: return "注音鍵位"
        }
    }
}

/// 一次練習 session 的完整記錄（持久化用）
struct PracticeSessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let mode: PracticeMode
    let date: Date
    let startTime: Date
    let endTime: Date
    let durationSeconds: Double
    let accuracy: Double
    let wpm: Double?
    let errorCount: Int
    let totalKeystrokes: Int
    let correctKeystrokes: Int
    /// 弱指目標（仅 weakFinger 模式）
    let weakFingerTarget: String?
    /// 疲勞分數（仅 weakFinger 模式）
    let fatigueScore: Int?
    /// 錯誤鍵統計（key → 次數）
    let errorKeys: [String: Int]

    init(
        id: UUID = UUID(),
        mode: PracticeMode,
        date: Date = Date(),
        startTime: Date,
        endTime: Date,
        durationSeconds: Double,
        accuracy: Double,
        wpm: Double? = nil,
        errorCount: Int,
        totalKeystrokes: Int,
        correctKeystrokes: Int,
        weakFingerTarget: String? = nil,
        fatigueScore: Int? = nil,
        errorKeys: [String: Int] = [:]
    ) {
        self.id = id
        self.mode = mode
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.accuracy = accuracy
        self.wpm = wpm
        self.errorCount = errorCount
        self.totalKeystrokes = totalKeystrokes
        self.correctKeystrokes = correctKeystrokes
        self.weakFingerTarget = weakFingerTarget
        self.fatigueScore = fatigueScore
        self.errorKeys = errorKeys
    }

    /// 從英文練習結果建立
    static func fromEnglish(result: PracticeResult, startTime: Date, endTime: Date) -> PracticeSessionRecord {
        let errorKeys = Dictionary(grouping: result.errors, by: { $0.actualChar })
            .mapValues { $0.count }
        return PracticeSessionRecord(
            mode: .english,
            date: Calendar.current.startOfDay(for: startTime),
            startTime: startTime,
            endTime: endTime,
            durationSeconds: result.durationSeconds,
            accuracy: result.accuracy,
            wpm: result.wpm,
            errorCount: result.errorCount,
            totalKeystrokes: result.totalKeystrokes,
            correctKeystrokes: result.correctKeystrokes,
            errorKeys: errorKeys
        )
    }

    /// 從弱指練習結果建立
    static func fromWeakFinger(result: WeakFingerResult, startTime: Date, endTime: Date) -> PracticeSessionRecord {
        return PracticeSessionRecord(
            mode: .weakFinger,
            date: Calendar.current.startOfDay(for: startTime),
            startTime: startTime,
            endTime: endTime,
            durationSeconds: endTime.timeIntervalSince(startTime),
            accuracy: result.accuracy,
            wpm: nil,
            errorCount: result.errorCount,
            totalKeystrokes: result.totalKeystrokes,
            correctKeystrokes: result.correctKeystrokes,
            weakFingerTarget: result.target.rawValue,
            fatigueScore: result.fatigueScore,
            errorKeys: result.errorKeys
        )
    }

    /// 從注音練習結果建立
    static func fromZhuyin(result: ZhuyinPracticeResult, startTime: Date, endTime: Date) -> PracticeSessionRecord {
        return PracticeSessionRecord(
            mode: .zhuyin,
            date: Calendar.current.startOfDay(for: startTime),
            startTime: startTime,
            endTime: endTime,
            durationSeconds: result.durationSeconds,
            accuracy: result.accuracy,
            wpm: nil,
            errorCount: result.totalErrors,
            totalKeystrokes: result.totalCorrect + result.totalErrors,
            correctKeystrokes: result.totalCorrect,
            errorKeys: result.keyErrorStats
        )
    }
}

/// 今日統計摘要
struct DashboardSummary {
    let todaySessionCount: Int
    let todayTotalSeconds: Double
    let todayAvgAccuracy: Double
    let todayTotalErrors: Int
    let topErrorKeys: [(key: String, count: Int)]
    let weakFingerWeaknesses: [String]
    let recentSessions: [PracticeSessionRecord]

    static var empty: DashboardSummary {
        DashboardSummary(
            todaySessionCount: 0,
            todayTotalSeconds: 0,
            todayAvgAccuracy: 0,
            todayTotalErrors: 0,
            topErrorKeys: [],
            weakFingerWeaknesses: [],
            recentSessions: []
        )
    }
}

/// 總統計摘要
struct StatsSummary {
    let totalSessions: Int
    let totalSeconds: Double
    let totalErrors: Int
    let totalKeystrokes: Int
    let avgAccuracy: Double
    let modeStats: [PracticeMode: ModeStats]
    let topErrorKeys: [(key: String, count: Int)]
    let recentSessions: [PracticeSessionRecord]

    static var empty: StatsSummary {
        StatsSummary(
            totalSessions: 0,
            totalSeconds: 0,
            totalErrors: 0,
            totalKeystrokes: 0,
            avgAccuracy: 0,
            modeStats: [:],
            topErrorKeys: [],
            recentSessions: []
        )
    }
}

struct ModeStats {
    let mode: PracticeMode
    let sessionCount: Int
    let totalSeconds: Double
    let avgAccuracy: Double
}