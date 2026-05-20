import XCTest
@testable import MacType

final class PracticeEngineTests: XCTestCase {

    // MARK: - 正確輸入推進游標並完成
    func testCorrectInput_advancesCursor() {
        let engine = PracticeEngine(targetText: "abc")
        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertFalse(engine.hasStarted)

        _ = engine.processInput("a")
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertTrue(engine.hasStarted)
        XCTAssertEqual(engine.correctKeystrokes, 1)
        XCTAssertEqual(engine.totalKeystrokes, 1)

        _ = engine.processInput("b")
        XCTAssertEqual(engine.currentIndex, 2)

        _ = engine.processInput("c")
        XCTAssertEqual(engine.currentIndex, 3)
        XCTAssertTrue(engine.isFinished)
    }

    func testCompletePractice_producesValidResult() {
        let engine = PracticeEngine(targetText: "hi")
        _ = engine.processInput("h")
        _ = engine.processInput("i")

        XCTAssertTrue(engine.isFinished)
        let result = engine.getResult()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.targetText, "hi")
        XCTAssertEqual(result?.correctKeystrokes, 2)
        XCTAssertEqual(result?.totalKeystrokes, 2)
        XCTAssertEqual(result?.errors.count, 0)
    }

    // MARK: - 錯誤輸入不推進且記錄錯誤
    func testWrongInput_doesNotAdvanceCursor() {
        let engine = PracticeEngine(targetText: "abc")
        _ = engine.processInput("x") // 錯誤

        XCTAssertEqual(engine.currentIndex, 0) // 游標未動
        XCTAssertEqual(engine.errors.count, 1)
        XCTAssertEqual(engine.errors[0].targetChar, "a")
        XCTAssertEqual(engine.errors[0].actualChar, "x")
    }

    func testWrongInput_countsTotalKeystroke() {
        let engine = PracticeEngine(targetText: "abc")
        _ = engine.processInput("x")

        XCTAssertEqual(engine.totalKeystrokes, 1)
        XCTAssertEqual(engine.correctKeystrokes, 0)
    }

    func testMultipleErrors_recordsAll() {
        let engine = PracticeEngine(targetText: "abc")
        _ = engine.processInput("x")
        _ = engine.processInput("y")
        _ = engine.processInput("a")
        _ = engine.processInput("z")

        XCTAssertEqual(engine.errors.count, 3)
        XCTAssertEqual(engine.currentIndex, 1) // 只有 a 正確
    }

    // MARK: - WPM / Accuracy / Error count
    func testWPM_calculation() {
        let result = PracticeResult(
            targetText: "hello",
            startTime: Date(),
            endTime: Date().addingTimeInterval(10), // 10 秒 = 10/60 分
            errors: [],
            totalKeystrokes: 5,
            correctKeystrokes: 5
        )
        // WPM = (5 / 5) / (10/60) = 1 / (1/6) = 6
        XCTAssertEqual(result.wpm, 6.0, accuracy: 0.01)
    }

    func testAccuracy_calculation() {
        let result = PracticeResult(
            targetText: "abc",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5),
            errors: [],
            totalKeystrokes: 10,
            correctKeystrokes: 7
        )
        // Accuracy = 7/10 * 100 = 70%
        XCTAssertEqual(result.accuracy, 70.0, accuracy: 0.01)
    }

    func testErrorCount_returnsDistinctErrors() {
        let errors = [
            TypingErrorRecord(index: 0, targetChar: "a", actualChar: "x"),
            TypingErrorRecord(index: 2, targetChar: "c", actualChar: "z"),
            TypingErrorRecord(index: 4, targetChar: "e", actualChar: "y")
        ]
        let result = PracticeResult(
            targetText: "abcde",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5),
            errors: errors,
            totalKeystrokes: 5,
            correctKeystrokes: 2
        )
        XCTAssertEqual(result.errorCount, 3)
    }

    // MARK: - Backspace
    func testBackspace_movesCursorBack() {
        let engine = PracticeEngine(targetText: "abc")
        _ = engine.processInput("a")
        XCTAssertEqual(engine.currentIndex, 1)

        engine.handleBackspace()
        XCTAssertEqual(engine.currentIndex, 0)
    }

    func testBackspace_doesNotGoBelowZero() {
        let engine = PracticeEngine(targetText: "abc")
        engine.handleBackspace()
        XCTAssertEqual(engine.currentIndex, 0)
    }

    // MARK: - Reset
    func testReset_restoresInitialState() {
        let engine = PracticeEngine(targetText: "abc")
        _ = engine.processInput("a")
        _ = engine.processInput("x")

        engine.reset()

        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertEqual(engine.errors.count, 0)
        XCTAssertEqual(engine.totalKeystrokes, 0)
        XCTAssertEqual(engine.correctKeystrokes, 0)
        XCTAssertFalse(engine.hasStarted)
        XCTAssertFalse(engine.isFinished)
    }

    func testReset_withNewText() {
        let engine = PracticeEngine(targetText: "abc")
        engine.reset(to: "xy")

        XCTAssertEqual(engine.targetText, "xy")
        XCTAssertEqual(engine.currentIndex, 0)
    }

    // MARK: - Pure simulate()
    func testSimulate_allCorrect() {
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a", "b", "c"])

        XCTAssertEqual(result.errors.count, 0)
        XCTAssertEqual(result.correctKeystrokes, 3)
        XCTAssertEqual(result.totalKeystrokes, 3)
    }

    func testSimulate_withErrors() {
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a", "x", "b", "y", "c"])

        XCTAssertEqual(result.errors.count, 2)
        XCTAssertEqual(result.correctKeystrokes, 3)
        XCTAssertEqual(result.totalKeystrokes, 5)
    }

    func testSimulate_extraInputs_ignored() {
        let result = PracticeEngine.simulate(targetText: "ab", inputs: ["a", "b", "c", "d"])

        XCTAssertEqual(result.correctKeystrokes, 2)
        XCTAssertEqual(result.totalKeystrokes, 2) // 第三個輸入被忽略
    }

    func testSimulate_incomplete() {
        let result = PracticeEngine.simulate(targetText: "abcd", inputs: ["a", "b"])

        XCTAssertEqual(result.correctKeystrokes, 2)
        XCTAssertEqual(result.totalKeystrokes, 2)
        XCTAssertEqual(result.errors.count, 0)
        XCTAssertFalse(result.isComplete)
    }

    // MARK: - isComplete 邏輯
    func testIsComplete_incompleteWithErrors() {
        // 未完成且有錯誤 → isComplete 必須 false
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["x"])
        XCTAssertFalse(result.isComplete)
        XCTAssertGreaterThan(result.errors.count, 0)
    }

    func testIsComplete_incompletePartialCorrectWithErrors() {
        // 部分正確 + 錯誤，仍未完成 → isComplete 必須 false
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a", "x"])
        XCTAssertFalse(result.isComplete)
        XCTAssertGreaterThan(result.errors.count, 0)
    }

    func testIsComplete_completeWithErrors() {
        // 完成（有錯誤仍算完成）
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a", "x", "b", "c"])
        XCTAssertTrue(result.isComplete)
    }

    func testIsComplete_completeNoErrors() {
        // 完成、無錯誤
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a", "b", "c"])
        XCTAssertTrue(result.isComplete)
        XCTAssertEqual(result.errors.count, 0)
    }

    func testIsComplete_incompleteNoErrors() {
        // 未完成、無錯誤
        let result = PracticeEngine.simulate(targetText: "abc", inputs: ["a"])
        XCTAssertFalse(result.isComplete)
    }

    // MARK: - Edge Cases
    func testEmptyTargetText() {
        let engine = PracticeEngine(targetText: "")
        _ = engine.processInput("a")

        XCTAssertEqual(engine.errors.count, 0) // 空字串不產生錯誤
        XCTAssertFalse(engine.isFinished)
    }

    func testGetCurrentChar_empty() {
        let engine = PracticeEngine(targetText: "")
        XCTAssertEqual(engine.getCurrentChar(), "")
    }
}