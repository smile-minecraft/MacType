import Foundation

/// 弱指練習引擎
/// 管理弱指練習狀態：目前 index、total/correct/errors、
/// 每次正確輸入的反應時間、fatigueScore
class WeakFingerPracticeEngine: ObservableObject {
    // ==== 狀態 ====
    @Published private(set) var targetText: String = ""
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var errors: [TypingErrorRecord] = []
    @Published private(set) var totalKeystrokes: Int = 0
    @Published private(set) var correctKeystrokes: Int = 0
    @Published private(set) var hasStarted: Bool = false
    @Published private(set) var isFinished: Bool = false
    @Published var fatigueScore: Int = 3

    /// 每次正確輸入的時間戳（用於計算反應時間）
    private var reactionTimestamps: [TimeInterval] = []
    private var lastKeystrokeTime: Date?
    private var startTime: Date?
    private var endTime: Date?

    /// 錯誤鍵計數
    private var errorKeyCounts: [String: Int] = [:]

    // ==== 初始化 ====
    init() {}

    // ==== 公開 API ====
    /// 設定目標與文句
    func setup(target: WeakFingerTarget, text: String) {
        self.targetText = text
        self.currentIndex = 0
        self.errors = []
        self.totalKeystrokes = 0
        self.correctKeystrokes = 0
        self.hasStarted = false
        self.isFinished = false
        self.fatigueScore = 3
        self.reactionTimestamps = []
        self.lastKeystrokeTime = nil
        self.startTime = nil
        self.endTime = nil
        self.errorKeyCounts = [:]
    }

    /// 處理一個鍵輸入
    @discardableResult
    func processInput(_ input: String) -> Bool {
        guard !isFinished, currentIndex < targetText.count else { return false }

        if !hasStarted {
            hasStarted = true
            startTime = Date()
        }

        let now = Date()
        totalKeystrokes += 1

        let expectedChar = getCurrentChar()

        if input == expectedChar {
            correctKeystrokes += 1

            // 記錄反應時間（距離上一個擊鍵）
            if let last = lastKeystrokeTime {
                reactionTimestamps.append(now.timeIntervalSince(last))
            }
            lastKeystrokeTime = now

            currentIndex += 1
            checkCompletion()
            return true
        } else {
            // 記錄錯誤
            let record = TypingErrorRecord(
                index: currentIndex,
                targetChar: expectedChar,
                actualChar: input
            )
            errors.append(record)
            errorKeyCounts[input, default: 0] += 1
            return false
        }
    }

    /// 取得目前 result
    func getResult() -> WeakFingerResult? {
        guard isFinished else { return nil }
        return WeakFingerResult(
            target: .leftPinky, //  caller should set target via setup
            accuracy: computeAccuracy(),
            averageReactionTime: computeAvgReactionTime(),
            errorKeys: errorKeyCounts,
            fatigueScore: fatigueScore,
            totalKeystrokes: totalKeystrokes,
            correctKeystrokes: correctKeystrokes
        )
    }

    /// 取得 result（帶 target 資訊）
    func getResult(for target: WeakFingerTarget) -> WeakFingerResult {
        WeakFingerResult(
            target: target,
            accuracy: computeAccuracy(),
            averageReactionTime: computeAvgReactionTime(),
            errorKeys: errorKeyCounts,
            fatigueScore: fatigueScore,
            totalKeystrokes: totalKeystrokes,
            correctKeystrokes: correctKeystrokes
        )
    }

    /// 重置
    func reset() {
        targetText = ""
        currentIndex = 0
        errors = []
        totalKeystrokes = 0
        correctKeystrokes = 0
        hasStarted = false
        isFinished = false
        reactionTimestamps = []
        lastKeystrokeTime = nil
        startTime = nil
        endTime = nil
        errorKeyCounts = [:]
        fatigueScore = 3
    }

    /// 提前結束練習（用於用戶主動結束）
    func finishEarly() {
        guard !isFinished else { return }
        isFinished = true
        endTime = Date()
    }

    // ==== 輔助 ====
    func getCurrentChar() -> String {
        guard currentIndex < targetText.count else { return "" }
        return String(targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)])
    }

    // ==== 私有 ====
    private func checkCompletion() {
        if currentIndex >= targetText.count {
            isFinished = true
            endTime = Date()
        }
    }

    private func computeAccuracy() -> Double {
        guard totalKeystrokes > 0 else { return 0 }
        return Double(correctKeystrokes) / Double(totalKeystrokes) * 100.0
    }

    private func computeAvgReactionTime() -> Double {
        guard !reactionTimestamps.isEmpty else { return 0 }
        return reactionTimestamps.reduce(0, +) / Double(reactionTimestamps.count)
    }
}