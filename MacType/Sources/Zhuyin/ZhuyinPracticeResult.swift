import Foundation

/// 注音練習結果
struct ZhuyinPracticeResult: Equatable {
    let mode: ZhuyinPracticeMode
    let order: ZhuyinQuestionOrder
    let startTime: Date
    let endTime: Date
    let totalQuestions: Int
    let totalCorrect: Int
    let totalErrors: Int
    let errorRecords: [TypingErrorRecord]
    let wordHintUsed: Bool

    var durationSeconds: Double {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Double {
        durationSeconds / 60.0
    }

    var accuracy: Double {
        let total = totalCorrect + totalErrors
        guard total > 0 else { return 0 }
        return Double(totalCorrect) / Double(total) * 100.0
    }

    /// 錯誤統計（symbol → 次數）
    var errorStats: [String: Int] {
        var stats: [String: Int] = [:]
        for record in errorRecords {
            let sym = record.targetChar
            stats[sym, default: 0] += 1
        }
        return stats
    }

    /// 錯誤鍵統計（key → 次數）
    var keyErrorStats: [String: Int] {
        var stats: [String: Int] = [:]
        for record in errorRecords {
            let key = record.actualChar
            stats[key, default: 0] += 1
        }
        return stats
    }
}