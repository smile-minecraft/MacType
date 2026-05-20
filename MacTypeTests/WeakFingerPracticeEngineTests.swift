import XCTest
@testable import MacType

final class WeakFingerPracticeEngineTests: XCTestCase {

    // MARK: - 正確輸入推進、錯誤不推進且記錄
    func testCorrectInput_advancesCursor() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")

        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertFalse(engine.hasStarted)

        _ = engine.processInput("a")
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertTrue(engine.hasStarted)
        XCTAssertEqual(engine.correctKeystrokes, 1)
        XCTAssertEqual(engine.totalKeystrokes, 1)

        _ = engine.processInput("a")
        XCTAssertEqual(engine.currentIndex, 2)

        _ = engine.processInput("a")
        XCTAssertEqual(engine.currentIndex, 3)
        XCTAssertTrue(engine.isFinished)
    }

    func testWrongInput_doesNotAdvanceCursor() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")
        _ = engine.processInput("x")

        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertEqual(engine.errors.count, 1)
        XCTAssertEqual(engine.errors[0].targetChar, "a")
        XCTAssertEqual(engine.errors[0].actualChar, "x")
    }

    func testWrongInput_countsTotalKeystroke() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")
        _ = engine.processInput("x")

        XCTAssertEqual(engine.totalKeystrokes, 1)
        XCTAssertEqual(engine.correctKeystrokes, 0)
    }

    func testMultipleErrors_recordsAll() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")
        _ = engine.processInput("x")
        _ = engine.processInput("y")
        _ = engine.processInput("a")
        _ = engine.processInput("z")

        XCTAssertEqual(engine.errors.count, 3)
        XCTAssertEqual(engine.currentIndex, 1)
    }

    // MARK: - 完成後 accuracy / averageReactionTime / errorKeys 正確
    func testComplete_Accuracy() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aa")

        _ = engine.processInput("a")
        _ = engine.processInput("a")

        let result = engine.getResult(for: .leftPinky)
        XCTAssertEqual(result.accuracy, 100.0, accuracy: 0.01)
    }

    func testComplete_withErrors_Accuracy() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")

        _ = engine.processInput("a")
        _ = engine.processInput("x")
        _ = engine.processInput("a")
        _ = engine.processInput("y")
        _ = engine.processInput("a")

        let result = engine.getResult(for: .leftPinky)
        // 3 correct / 5 total = 60%
        XCTAssertEqual(result.accuracy, 60.0, accuracy: 0.01)
    }

    func testComplete_errorKeys() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")

        _ = engine.processInput("x")
        _ = engine.processInput("a")
        _ = engine.processInput("x")

        let result = engine.getResult(for: .leftPinky)
        XCTAssertEqual(result.errorKeys["x"], 2)
    }

    func testComplete_reactionTime_isNonNegative() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aa")

        _ = engine.processInput("a")
        Thread.sleep(forTimeInterval: 0.01)
        _ = engine.processInput("a")

        let result = engine.getResult(for: .leftPinky)
        XCTAssertGreaterThanOrEqual(result.averageReactionTime, 0)
    }

    // MARK: - fatigueScore 可設定且保留
    func testFatigueScore_defaultValue() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "a")
        XCTAssertEqual(engine.fatigueScore, 3)
    }

    func testFatigueScore_canBeSet() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "a")
        engine.fatigueScore = 5
        XCTAssertEqual(engine.fatigueScore, 5)

        _ = engine.processInput("a")
        let result = engine.getResult(for: .leftPinky)
        XCTAssertEqual(result.fatigueScore, 5)
    }

    func testFatigueScore_preservedInResult() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .rightRing, text: "oo")

        engine.fatigueScore = 4
        _ = engine.processInput("o")
        _ = engine.processInput("o")

        let result = engine.getResult(for: .rightRing)
        XCTAssertEqual(result.fatigueScore, 4)
    }

    // MARK: - reset 正常
    func testReset_restoresInitialState() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")
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

    func testReset_thenNewSetup() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "aaa")
        engine.reset()
        engine.setup(target: .rightPinky, text: "pp")

        XCTAssertEqual(engine.targetText, "pp")
        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertFalse(engine.isFinished)
    }

    // MARK: - isFinished only after all chars typed
    func testIsFinished_onlyWhenComplete() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "a")

        XCTAssertFalse(engine.isFinished)
        _ = engine.processInput("a")
        XCTAssertTrue(engine.isFinished)
    }

    // MARK: - processInput_afterFinish_ignored
    func testProcessInput_afterFinish_ignored() {
        let engine = WeakFingerPracticeEngine()
        engine.setup(target: .leftPinky, text: "a")

        _ = engine.processInput("a")
        XCTAssertTrue(engine.isFinished)

        _ = engine.processInput("a")
        XCTAssertEqual(engine.totalKeystrokes, 1) // 不再增加
    }
}