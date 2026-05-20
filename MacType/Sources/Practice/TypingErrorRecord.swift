import Foundation

/// 單筆打字錯誤記錄
struct TypingErrorRecord: Codable, Identifiable, Equatable {
    /// 錯誤發生時的 index（target 字串中的位置）
    let index: Int
    /// 預期要打的字元
    let targetChar: String
    /// 實際輸入的字元
    let actualChar: String
    /// 錯誤發生時間（Date.timeIntervalSince1970）
    let timestamp: TimeInterval

    /// 唯一識別：使用 index + timestamp 複合，確保同 index 多錯誤不衝突
    var id: String { "\(index)-\(timestamp)" }

    init(index: Int, targetChar: String, actualChar: String, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.index = index
        self.targetChar = targetChar
        self.actualChar = actualChar
        self.timestamp = timestamp
    }
}