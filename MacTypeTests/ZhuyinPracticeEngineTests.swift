import XCTest
@testable import MacType

final class ZhuyinPracticeEngineTests: XCTestCase {
    // MARK: - Single Symbol: Correct
    func test_single_symbol_correct_advances() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 3, seed: nil)
        engine.setQuestions(questions)

        let firstKey = engine.currentExpectedKey!
        let (isCorrect, _) = engine.processKey(firstKey)

        XCTAssertTrue(isCorrect)
        XCTAssertEqual(engine.totalCorrect, 1)
        XCTAssertEqual(engine.totalErrors, 0)
        XCTAssertEqual(engine.currentQuestionIndex, 1)
    }

    // MARK: - Single Symbol: Wrong
    func test_single_symbol_wrong_does_not_advance_and_records_error() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 3, seed: nil)
        engine.setQuestions(questions)

        let correctKey = engine.currentExpectedKey!
        let wrongKey = correctKey == "a" ? "b" : "a"  // guaranteed wrong

        let (isCorrect, _) = engine.processKey(wrongKey)

        XCTAssertFalse(isCorrect)
        XCTAssertEqual(engine.totalErrors, 1)
        XCTAssertEqual(engine.totalCorrect, 0)
        XCTAssertEqual(engine.currentQuestionIndex, 0)  // 未前進
        XCTAssertTrue(engine.showHint)
        XCTAssertFalse(engine.errorRecords.isEmpty)
    }

    // MARK: - Syllable: Sequential Input
    func test_syllable_sequential_input_correct_sequence() {
        let engine = ZhuyinPracticeEngine(mode: .syllable, order: .sequential)
        // 手動建立含 2 個符號的音節題目
        let sym1 = ZhuyinSymbol("ㄅ")
        let sym2 = ZhuyinSymbol("ㄚ")
        let key1 = ZhuyinStandardMap.symbolToKey[sym1]!
        let key2 = ZhuyinStandardMap.symbolToKey[sym2]!
        let question = ZhuyinQuestion(symbols: [sym1, sym2], expectedKeys: [key1, key2])
        engine.setQuestions([question])

        // 第一個符號
        let (c1, _) = engine.processKey(key1)
        XCTAssertTrue(c1)
        XCTAssertEqual(engine.totalCorrect, 1)
        XCTAssertEqual(engine.currentSymbolIndex, 1)  // 已advance到第二個

        // 第二個符號
        let (c2, _) = engine.processKey(key2)
        XCTAssertTrue(c2)
        XCTAssertEqual(engine.totalCorrect, 2)
        XCTAssertEqual(engine.currentQuestionIndex, 1)  // 音節完成，前進到下一題
    }

    // MARK: - Syllable: Wrong Input
    func test_syllable_wrong_input_does_not_advance_symbol() {
        let engine = ZhuyinPracticeEngine(mode: .syllable, order: .sequential)
        let sym1 = ZhuyinSymbol("ㄅ")
        let sym2 = ZhuyinSymbol("ㄚ")
        let key1 = ZhuyinStandardMap.symbolToKey[sym1]!
        let wrongKey = "z"  // guaranteed wrong
        let question = ZhuyinQuestion(symbols: [sym1, sym2], expectedKeys: [key1, "8"])
        engine.setQuestions([question])

        let (isCorrect, _) = engine.processKey(wrongKey)

        XCTAssertFalse(isCorrect)
        XCTAssertEqual(engine.totalErrors, 1)
        XCTAssertEqual(engine.currentSymbolIndex, 0)  // 未前進
        XCTAssertTrue(engine.showHint)
    }

    // MARK: - Result: Accuracy
    func test_result_accuracy_calculation() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 2, seed: nil)
        engine.setQuestions(questions)

        // 答對第一題
        _ = engine.processKey(engine.currentExpectedKey!)
        // 答錯第二題
        _ = engine.processKey("z")
        // 再答對（補救）
        _ = engine.processKey(engine.currentExpectedKey!)

        // 手動標記完成以取得 result
        engine.advanceToNextQuestion()

        XCTAssertEqual(engine.totalCorrect, 2)
        XCTAssertEqual(engine.totalErrors, 1)
    }

    // MARK: - Reset
    func test_reset_clears_state() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 3, seed: nil)
        engine.setQuestions(questions)

        // 輸入一些數據
        _ = engine.processKey("1")
        _ = engine.processKey("z")

        engine.reset()

        XCTAssertEqual(engine.totalCorrect, 0)
        XCTAssertEqual(engine.totalErrors, 0)
        XCTAssertEqual(engine.currentQuestionIndex, 0)
        XCTAssertEqual(engine.currentSymbolIndex, 0)
        XCTAssertFalse(engine.showHint)
    }

    // MARK: - Completion
    func test_engine_finishes_when_all_questions_done() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 2, seed: nil)
        engine.setQuestions(questions)

        // 完成所有題目：single symbol 模式下 processKey 答對後會自動 advance
        // 所以不需要手動呼叫 advanceToNextQuestion()
        guard let key1 = engine.currentExpectedKey else {
            XCTFail("Expected first key")
            return
        }
        _ = engine.processKey(key1)

        guard let key2 = engine.currentExpectedKey else {
            XCTFail("Expected second key")
            return
        }
        _ = engine.processKey(key2)

        XCTAssertTrue(engine.isFinished)
        XCTAssertNotNil(engine.getResult())
    }

    // MARK: - Configure: Mode/Order Update
    func test_configure_updates_mode_and_order() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        
        // 初始 mode/order 為 singleSymbol/sequential
        XCTAssertEqual(engine.mode, .singleSymbol)
        XCTAssertEqual(engine.order, .sequential)
        
        // configure 後更新為 syllable/random
        engine.configure(mode: .syllable, order: .random)
        
        XCTAssertEqual(engine.mode, .syllable)
        XCTAssertEqual(engine.order, .random)
    }

    // MARK: - Result: Syllable Mode Metadata
    func test_result_metadata_reflects_syllable_mode() {
        let engine = ZhuyinPracticeEngine(mode: .syllable, order: .random)
        let sym1 = ZhuyinSymbol("ㄅ")
        let sym2 = ZhuyinSymbol("ㄚ")
        let key1 = ZhuyinStandardMap.symbolToKey[sym1]!
        let key2 = ZhuyinStandardMap.symbolToKey[sym2]!
        let question = ZhuyinQuestion(symbols: [sym1, sym2], expectedKeys: [key1, key2])
        engine.setQuestions([question])

        // 完成題目
        _ = engine.processKey(key1)
        _ = engine.processKey(key2)

        guard let result = engine.getResult() else {
            XCTFail("Expected result")
            return
        }

        // 驗證 result metadata 與 engine 配置一致
        XCTAssertEqual(result.mode, .syllable)
        XCTAssertEqual(result.order, .random)
    }

    // MARK: - Result: Random Order Metadata
    func test_result_metadata_reflects_random_order() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .random)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 2, seed: nil)
        engine.setQuestions(questions)

        // 完成題目
        guard let key1 = engine.currentExpectedKey else {
            XCTFail("Expected first key")
            return
        }
        _ = engine.processKey(key1)
        
        guard let key2 = engine.currentExpectedKey else {
            XCTFail("Expected second key")
            return
        }
        _ = engine.processKey(key2)

        guard let result = engine.getResult() else {
            XCTFail("Expected result")
            return
        }

        // 驗證 result metadata 與 engine 配置一致
        XCTAssertEqual(result.mode, .singleSymbol)
        XCTAssertEqual(result.order, .random)
    }

    // MARK: - Progress: Clamp on Completion
    func test_progress_clamped_after_completion() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 2, seed: nil)
        engine.setQuestions(questions)

        // 初始進度
        XCTAssertEqual(engine.progress, "1 / 2")

        // 完成第一題
        guard let key1 = engine.currentExpectedKey else {
            XCTFail("Expected first key")
            return
        }
        _ = engine.processKey(key1)

        // 進度應為 2 / 2
        XCTAssertEqual(engine.progress, "2 / 2")

        // 完成第二題（此時 isFinished = true）
        guard let key2 = engine.currentExpectedKey else {
            XCTFail("Expected second key")
            return
        }
        _ = engine.processKey(key2)

        // 完成後進度不應超過 total，應顯示 2 / 2 而非 3 / 2
        XCTAssertEqual(engine.progress, "2 / 2")
    }

    // MARK: - Result: keyErrorStats Uses actualChar
    func test_keyErrorStats_uses_actualChar_not_targetChar() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 1, seed: nil)
        engine.setQuestions(questions)

        // 預期鍵是 "1"，但按錯成 "2"
        _ = engine.processKey("2")

        // 完成題目以取得 result
        guard let key = engine.currentExpectedKey else {
            XCTFail("Expected key")
            return
        }
        _ = engine.processKey(key)

        guard let result = engine.getResult() else {
            XCTFail("Expected result")
            return
        }

        // keyErrorStats 應該統計 actualChar ("2")，不是 targetChar ("1")
        let keyStats = result.keyErrorStats
        XCTAssertEqual(keyStats["2"], 1, "keyErrorStats should count actual pressed key '2'")
        XCTAssertNil(keyStats["1"], "keyErrorStats should NOT count target key '1'")
    }

    // MARK: - Result: errorStats Uses targetChar
    func test_errorStats_uses_targetChar() {
        let engine = ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential)
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 1, seed: nil)
        engine.setQuestions(questions)

        // 預期鍵是 "1"，但按錯成 "2"
        _ = engine.processKey("2")

        // 完成題目以取得 result
        guard let key = engine.currentExpectedKey else {
            XCTFail("Expected key")
            return
        }
        _ = engine.processKey(key)

        guard let result = engine.getResult() else {
            XCTFail("Expected result")
            return
        }

        // errorStats 應該統計 targetChar ("1")，不是 actualChar ("2")
        let symStats = result.errorStats
        XCTAssertEqual(symStats["1"], 1, "errorStats should count target symbol '1'")
        XCTAssertNil(symStats["2"], "errorStats should NOT count actual pressed key '2'")
    }
}