import Foundation

/// 鍵盤按鍵狀態
enum KeyState: Int, Comparable {
    case keyDefault = 0      // 預設
    case keyPressed = 1      // 剛按下
    case keyTarget = 2       // 目標鍵（下一個要按的）
    case keyError = 3        // 錯誤

    /// 比較優先權（數字越大優先權越高）
    static func < (lhs: KeyState, rhs: KeyState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 解析按鍵狀態（純函式，便於測試）
    /// - Parameters:
    ///   - key: 要查詢的按鍵字元
    ///   - targetKey: 目前練習的目標字元（可能多個，如大小寫）
    ///   - pressedKey: 剛按下的字元
    ///   - errorKey: 最後錯誤的字元
    /// - Returns: 該鍵的最高優先權狀態
    static func resolve(
        key: String,
        targetKey: String?,
        pressedKey: String?,
        errorKey: String?
    ) -> KeyState {
        // 錯誤狀態優先（3）
        if let err = errorKey, matches(key: key, other: err) {
            return .keyError
        }
        // 目標狀態次之（2）
        if let target = targetKey, matches(key: key, other: target) {
            return .keyTarget
        }
        // 剛按下狀態（1）
        if let pressed = pressedKey, matches(key: key, other: pressed) {
            return .keyPressed
        }
        // 預設（0）
        return .keyDefault
    }

    /// 判斷是否為英文字母（大小寫）
    private static func isLetter(_ char: String) -> Bool {
        guard let first = char.first else { return false }
        return first.isLetter && first.isASCII
    }

    /// 比對兩個字元是否匹配（英文字母大小寫視為相同，空白與標點 exact match）
    private static func matches(key: String, other: String) -> Bool {
        // 空白與標點必須 exact match
        if !isLetter(key) || !isLetter(other) {
            return key == other
        }
        // 英文字母大小寫視為相同
        return key.lowercased() == other.lowercased()
    }

    /// 批次解析（純函式，供測試與批量計算）
    static func resolveAll(
        keys: [String],
        targetKey: String?,
        pressedKey: String?,
        errorKey: String?
    ) -> [String: KeyState] {
        var result: [String: KeyState] = [:]
        for key in keys {
            result[key] = resolve(key: key, targetKey: targetKey, pressedKey: pressedKey, errorKey: errorKey)
        }
        return result
    }
}