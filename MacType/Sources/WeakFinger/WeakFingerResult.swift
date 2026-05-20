import Foundation

/// 弱指練習結果
struct WeakFingerResult: Equatable {
    /// 訓練目標
    let target: WeakFingerTarget
    /// 正確率（0.0~100.0）
    let accuracy: Double
    /// 平均反應時間（秒）
    let averageReactionTime: Double
    /// 錯誤鍵統計（鍵 → 次數）
    let errorKeys: [String: Int]
    /// 疲勞分數（1~5）
    let fatigueScore: Int

    /// 總擊鍵數
    let totalKeystrokes: Int
    /// 正確擊鍵數
    let correctKeystrokes: Int
    /// 錯誤擊鍵數（distinct error count）
    var errorCount: Int { errorKeys.values.reduce(0, +) }

    init(
        target: WeakFingerTarget,
        accuracy: Double,
        averageReactionTime: Double,
        errorKeys: [String: Int],
        fatigueScore: Int,
        totalKeystrokes: Int,
        correctKeystrokes: Int
    ) {
        self.target = target
        self.accuracy = accuracy
        self.averageReactionTime = averageReactionTime
        self.errorKeys = errorKeys
        self.fatigueScore = fatigueScore
        self.totalKeystrokes = totalKeystrokes
        self.correctKeystrokes = correctKeystrokes
    }
}