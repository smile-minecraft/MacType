import Foundation

/// 練習引擎：管理一次練習的狀態與邏輯
/// 可作為 ObservableObject（供 SwiftUI 使用）或純類別（易於測試）
class PracticeEngine: ObservableObject {
    // ==== 練習文句 ====
    /// 預設練習句子
    static let defaultSentence = "The quick brown fox jumps over the lazy dog."

    // ==== 狀態 ====
    /// 當前練習文句
    @Published private(set) var targetText: String
    /// 目前游標位置（下一個要打的字元 index）
    @Published private(set) var currentIndex: Int = 0
    /// 錯誤記錄
    @Published private(set) var errors: [TypingErrorRecord] = []
    /// 總擊鍵數（含錯誤）
    @Published private(set) var totalKeystrokes: Int = 0
    /// 正確擊鍵數
    @Published private(set) var correctKeystrokes: Int = 0
    /// 練習是否已開始
    @Published private(set) var hasStarted: Bool = false
    /// 練習是否已完成
    @Published private(set) var isFinished: Bool = false
    /// 練習開始時間
    private var startTime: Date?
    /// 練習結束時間
    private var endTime: Date?

    // ==== 初始化 ====
    init(targetText: String = PracticeEngine.defaultSentence) {
        self.targetText = targetText
    }

    // ==== 公開 API ====
    /// 處理一個鍵輸入
    /// - Parameter input: 正規化後的字元
    /// - Returns: 該輸入是否正確
    @discardableResult
    func processInput(_ input: String) -> Bool {
        guard !isFinished, hasValidCurrentChar() else { return false }

        // 尚未開始時，第一個有效輸入觸發計時
        if !hasStarted {
            hasStarted = true
            startTime = Date()
        }

        let expectedChar = getCurrentChar()
        totalKeystrokes += 1

        if input == expectedChar {
            correctKeystrokes += 1
            advanceCursor()
            checkCompletion()
            return true
        } else {
            recordError(actual: input)
            return false
        }
    }

    /// 處理 backspace（將游標往回一格）
    func handleBackspace() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    /// 重置練習
    func reset(to text: String? = nil) {
        if let text = text {
            targetText = text
        }
        currentIndex = 0
        errors = []
        totalKeystrokes = 0
        correctKeystrokes = 0
        hasStarted = false
        isFinished = false
        startTime = nil
        endTime = nil
    }

    /// 取得目前 result（若已完成）
    func getResult() -> PracticeResult? {
        guard isFinished, let start = startTime, let end = endTime else { return nil }
        return PracticeResult(
            targetText: targetText,
            startTime: start,
            endTime: end,
            errors: errors,
            totalKeystrokes: totalKeystrokes,
            correctKeystrokes: correctKeystrokes
        )
    }

    // ==== 輔助方法 ====
    /// 目前位置的預期字元
    func getCurrentChar() -> String {
        guard hasValidCurrentChar() else { return "" }
        return String(targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)])
    }

    /// 錯誤時的替代字元（如 shift modifier 無法區分大小寫時）
    func getExpectedCharLowercased() -> String {
        getCurrentChar().lowercased()
    }

    /// 錯誤時的替代字元（如 shift modifier 無法區分大小寫時）
    func getExpectedCharUppercased() -> String {
        getCurrentChar().uppercased()
    }

    /// 檢查大小寫是否匹配（考虑 shift 的情况）
    func matchesCaseInsensitive(actual: String, expected: String) -> Bool {
        // 純字母時，檢查大小寫是否正確
        if expected.first?.isLetter == true {
            if expected.first?.isUppercase == true {
                return actual == expected.uppercased()
            } else {
                return actual == expected.lowercased()
            }
        }
        return actual == expected
    }

    /// 已打完所有字元
    var allCharactersTyped: Bool {
        currentIndex >= targetText.count
    }

    // ==== 私有方法 ====
    private func hasValidCurrentChar() -> Bool {
        currentIndex >= 0 && currentIndex < targetText.count
    }

    private func advanceCursor() {
        currentIndex += 1
    }

    private func recordError(actual: String) {
        let record = TypingErrorRecord(
            index: currentIndex,
            targetChar: getCurrentChar(),
            actualChar: actual
        )
        errors.append(record)
    }

    private func checkCompletion() {
        if currentIndex >= targetText.count {
            isFinished = true
            endTime = Date()
        }
    }
}

// MARK: - Pure Swift 純函式版本（供測試使用）
extension PracticeEngine {
    /// 純函式版本：不依賴狀態，適用於自動化測試
    /// - Parameters:
    ///   - targetText: 目標文句
    ///   - inputs: 輸入序列（正規化後）
    /// - Returns: PracticeResult
    static func simulate(targetText: String, inputs: [String]) -> PracticeResult {
        var index = 0
        var errors: [TypingErrorRecord] = []
        var total = 0
        var correct = 0
        let start = Date()

        for (i, input) in inputs.enumerated() {
            guard index < targetText.count else { break }
            total += 1
            let expected = String(targetText[targetText.index(targetText.startIndex, offsetBy: index)])
            if input == expected {
                correct += 1
                index += 1
            } else {
                errors.append(TypingErrorRecord(index: index, targetChar: expected, actualChar: input))
            }
        }

        let end = Date()
        return PracticeResult(
            targetText: targetText,
            startTime: start,
            endTime: end,
            errors: errors,
            totalKeystrokes: total,
            correctKeystrokes: correct
        )
    }
}