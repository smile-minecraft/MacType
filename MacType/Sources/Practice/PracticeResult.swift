import Foundation

/// 練習結果（一次完整練習後的結算資料）
struct PracticeResult: Equatable {
    /// 練習文句
    let targetText: String
    /// 開始時間
    let startTime: Date
    /// 結束時間
    let endTime: Date
    /// 錯誤記錄
    let errors: [TypingErrorRecord]
    /// 總輸入次數（含錯誤擊鍵）
    let totalKeystrokes: Int
    /// 正確輸入次數
    let correctKeystrokes: Int

    /// 耗時（秒）
    var durationSeconds: Double {
        endTime.timeIntervalSince(startTime)
    }

    /// 耗時（分）
    var durationMinutes: Double {
        durationSeconds / 60.0
    }

    /// WPM = (正確字元數 / 5) / minutes
    /// 標準打字速度計算公式：每個詞視為 5 個字元
    var wpm: Double {
        guard durationMinutes > 0 else { return 0 }
        return Double(correctKeystrokes) / 5.0 / durationMinutes
    }

    /// Accuracy = 正確擊鍵數 / 總有意義擊鍵數（不含 backspace 修正）
    /// 使用 totalKeystrokes 當分母是更嚴格的標準
    var accuracy: Double {
        guard totalKeystrokes > 0 else { return 0 }
        return Double(correctKeystrokes) / Double(totalKeystrokes) * 100.0
    }

    /// 錯誤字元數（distinct errors，不重複計算同一位置的錯誤）
    var errorCount: Int {
        errors.count
    }

    /// 已完成（打完 targetText 全域為止）
    var isComplete: Bool {
        correctKeystrokes >= targetText.count
    }

    init(
        targetText: String,
        startTime: Date,
        endTime: Date,
        errors: [TypingErrorRecord],
        totalKeystrokes: Int,
        correctKeystrokes: Int
    ) {
        self.targetText = targetText
        self.startTime = startTime
        self.endTime = endTime
        self.errors = errors
        self.totalKeystrokes = totalKeystrokes
        self.correctKeystrokes = correctKeystrokes
    }
}