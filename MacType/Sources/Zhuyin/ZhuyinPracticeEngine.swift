import Foundation

/// 注音練習模式
enum ZhuyinPracticeMode: String, CaseIterable, Identifiable {
    case singleSymbol = "Single Symbol"
    case syllable = "Syllable"

    var id: String { rawValue }
}

/// 注音題目順序
enum ZhuyinQuestionOrder: String, CaseIterable, Identifiable {
    case sequential = "Sequential"
    case random = "Random"

    var id: String { rawValue }
}

/// 注音題目結構
struct ZhuyinQuestion: Equatable {
    /// 構成的注音符號序列（如 syllable 模式有多個）
    let symbols: [ZhuyinSymbol]
    /// 預期鍵位序列（與 symbols 對應）
    let expectedKeys: [String]

    var isSingle: Bool { symbols.count == 1 }
    var displayText: String { symbols.map(\.displayText).joined() }

    /// 第 N 個符號（N=0 base）
    subscript(n: Int) -> ZhuyinSymbol? {
        guard n >= 0, n < symbols.count else { return nil }
        return symbols[n]
    }

    /// 第 N 個預期鍵
    func key(at n: Int) -> String? {
        guard n >= 0, n < expectedKeys.count else { return nil }
        return expectedKeys[n]
    }

    var length: Int { symbols.count }
}

/// 注音練習引擎：管理題目序列與練習狀態
class ZhuyinPracticeEngine: ObservableObject {
    // ==== 模式與順序 ====
    private(set) var mode: ZhuyinPracticeMode
    private(set) var order: ZhuyinQuestionOrder

    // ==== 狀態 ====
    @Published private(set) var questions: [ZhuyinQuestion] = []
    @Published private(set) var currentQuestionIndex: Int = 0
    @Published private(set) var currentSymbolIndex: Int = 0   // syllable 內的當前位置
    @Published private(set) var totalCorrect: Int = 0
    @Published private(set) var totalErrors: Int = 0
    @Published private(set) var errorRecords: [TypingErrorRecord] = []
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var showHint: Bool = false        // 答錯後顯示 hint

    // 練習開始時間
    private var startTime: Date?
    private var endTime: Date?

    // ==== 初始化 ====
    init(mode: ZhuyinPracticeMode, order: ZhuyinQuestionOrder) {
        self.mode = mode
        self.order = order
    }

    /// 配置 engine 的模式與順序（startPractice 時呼叫）
    func configure(mode: ZhuyinPracticeMode, order: ZhuyinQuestionOrder) {
        self.mode = mode
        self.order = order
    }

    // MARK: - 題目生成
    /// 注入題目（通常來自 LessonGenerator）
    func setQuestions(_ questions: [ZhuyinQuestion]) {
        self.questions = order == .random ? questions.shuffled() : questions
        resetState()
    }

    /// 注入帶 seed 的隨機種子（deterministic random）
    func setQuestionsWithSeed(_ questions: [ZhuyinQuestion], seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        let shuffled = questions.shuffled(using: &rng)
        self.questions = shuffled
        resetState()
    }

    // MARK: - 公開 API
    /// 處理一個鍵輸入
    /// - Returns: (isCorrect, isQuestionComplete)
    @discardableResult
    func processKey(_ input: String) -> (isCorrect: Bool, isQuestionComplete: Bool) {
        guard !isFinished else { return (false, false) }

        if startTime == nil {
            startTime = Date()
        }

        let question = currentQuestion
        let expectedKey = question.key(at: currentSymbolIndex)

        guard let expected = expectedKey else {
            return (false, false)
        }

        let isCorrect = input == expected

        if isCorrect {
            totalCorrect += 1
            showHint = false
            advanceSymbol()
            return (true, currentSymbolIndex == 0 && currentQuestionIndex > 0)
        } else {
            totalErrors += 1
            let record = TypingErrorRecord(
                index: currentQuestionIndex * 10 + currentSymbolIndex,
                targetChar: expected,
                actualChar: input
            )
            errorRecords.append(record)
            showHint = true
            return (false, false)
        }
    }

    /// 完成當前題目並前進到下一題
    /// 僅在 syllable 模式下完整輸入後調用，或 single symbol 答對後自動調用
    func advanceToNextQuestion() {
        currentQuestionIndex += 1
        currentSymbolIndex = 0
        showHint = false
        checkFinished()
    }

    /// 重置練習（保留 mode/order，重新開始）
    func reset() {
        resetState()
        if order == .random {
            questions = questions.shuffled()
        }
    }

    /// 取得結果（若已完成）
    func getResult() -> ZhuyinPracticeResult? {
        guard isFinished, let start = startTime, let end = endTime else { return nil }
        return ZhuyinPracticeResult(
            mode: mode,
            order: order,
            startTime: start,
            endTime: end,
            totalQuestions: questions.count,
            totalCorrect: totalCorrect,
            totalErrors: totalErrors,
            errorRecords: errorRecords,
            wordHintUsed: false
        )
    }

    // MARK: - 輔助屬性
    /// 目前題目
    var currentQuestion: ZhuyinQuestion {
        guard currentQuestionIndex < questions.count else {
            return ZhuyinQuestion(symbols: [], expectedKeys: [])
        }
        return questions[currentQuestionIndex]
    }

    /// 目前需要按的鍵
    var currentExpectedKey: String? {
        currentQuestion.key(at: currentSymbolIndex)
    }

    /// 目前要顯示的注音符號（syllable 模式下為整個音節，single symbol 模式下為單符號）
    var currentDisplaySymbol: String {
        currentQuestion.displayText
    }

    /// 目前要顯示的所有符號（含已完成的，用於 UI）
    var currentAllSymbols: [ZhuyinSymbol] {
        currentQuestion.symbols
    }

    /// 進度（clamp 到 total）
    var progress: String {
        let current = min(currentQuestionIndex + 1, questions.count)
        return "\(current) / \(questions.count)"
    }

    // MARK: - 私有方法
    private func advanceSymbol() {
        let nextIndex = currentSymbolIndex + 1
        if nextIndex >= currentQuestion.length {
            // 完整輸入一個音節，前進到下一題
            advanceToNextQuestion()
        } else {
            currentSymbolIndex = nextIndex
        }
    }

    private func checkFinished() {
        if currentQuestionIndex >= questions.count {
            isFinished = true
            endTime = Date()
        }
    }

    private func resetState() {
        currentQuestionIndex = 0
        currentSymbolIndex = 0
        totalCorrect = 0
        totalErrors = 0
        errorRecords = []
        isFinished = false
        showHint = false
        startTime = nil
        endTime = nil
    }
}

// MARK: - Seeded Random（確定性隨機，供測試用）
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - 純函式版本（供測試）
extension ZhuyinPracticeEngine {
    /// 模擬一次練習（純函式）
    static func simulate(
        questions: [ZhuyinQuestion],
        inputs: [(questionIndex: Int, symbolIndex: Int, key: String)],
        mode: ZhuyinPracticeMode,
        order: ZhuyinQuestionOrder
    ) -> (totalCorrect: Int, totalErrors: Int, errorRecords: [TypingErrorRecord]) {
        var totalCorrect = 0
        var totalErrors = 0
        var errorRecords: [TypingErrorRecord] = []
        var currentQ = 0
        var currentS = 0

        for input in inputs {
            guard currentQ < questions.count else { break }
            let q = questions[currentQ]
            guard let expected = q.key(at: currentS) else {
                currentQ += 1
                currentS = 0
                continue
            }

            if input.key == expected {
                totalCorrect += 1
                currentS += 1
                if currentS >= q.length {
                    currentQ += 1
                    currentS = 0
                }
            } else {
                totalErrors += 1
                errorRecords.append(TypingErrorRecord(
                    index: currentQ * 10 + currentS,
                    targetChar: expected,
                    actualChar: input.key
                ))
            }
        }

        return (totalCorrect, totalErrors, errorRecords)
    }
}