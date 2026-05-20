import XCTest
@testable import MacType

final class KeyStateTests: XCTestCase {

    // MARK: - Priority Ordering
    func testKeyStatePriority_errorHighest() {
        XCTAssertGreaterThan(KeyState.keyError, KeyState.keyTarget)
        XCTAssertGreaterThan(KeyState.keyError, KeyState.keyPressed)
        XCTAssertGreaterThan(KeyState.keyError, KeyState.keyDefault)
    }

    func testKeyStatePriority_targetSecond() {
        XCTAssertGreaterThan(KeyState.keyTarget, KeyState.keyPressed)
        XCTAssertGreaterThan(KeyState.keyTarget, KeyState.keyDefault)
    }

    func testKeyStatePriority_pressedThird() {
        XCTAssertGreaterThan(KeyState.keyPressed, KeyState.keyDefault)
    }

    // MARK: - Resolve: Single Key
    func testResolve_errorKey() {
        let state = KeyState.resolve(key: "a", targetKey: "b", pressedKey: "c", errorKey: "a")
        XCTAssertEqual(state, .keyError)
    }

    func testResolve_targetKey() {
        let state = KeyState.resolve(key: "a", targetKey: "a", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_pressedKey() {
        let state = KeyState.resolve(key: "a", targetKey: "b", pressedKey: "a", errorKey: nil)
        XCTAssertEqual(state, .keyPressed)
    }

    func testResolve_defaultKey() {
        let state = KeyState.resolve(key: "a", targetKey: "b", pressedKey: "c", errorKey: nil)
        XCTAssertEqual(state, .keyDefault)
    }

    func testResolve_nilInputs() {
        let state = KeyState.resolve(key: "a", targetKey: nil, pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyDefault)
    }

    func testResolve_targetTakesPrecedenceOverPressed() {
        // 同時滿足 target 與 pressed，target 優先
        let state = KeyState.resolve(key: "a", targetKey: "a", pressedKey: "a", errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_errorTakesPrecedenceOverTarget() {
        // 同時滿足 error 與 target，error 優先
        let state = KeyState.resolve(key: "a", targetKey: "a", pressedKey: nil, errorKey: "a")
        XCTAssertEqual(state, .keyError)
    }

    // MARK: - ResolveAll
    func testResolveAll_returnsAllKeysWithState() {
        let keys = ["a", "b", "c"]
        let result = KeyState.resolveAll(keys: keys, targetKey: "a", pressedKey: "b", errorKey: nil)
        XCTAssertEqual(result["a"], .keyTarget)
        XCTAssertEqual(result["b"], .keyPressed)
        XCTAssertEqual(result["c"], .keyDefault)
    }

    func testResolveAll_emptyKeys() {
        let result = KeyState.resolveAll(keys: [], targetKey: "a", pressedKey: nil, errorKey: nil)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Case Insensitive Matching for Letters
    func testResolve_lowercaseTargetMapsToUppercaseKey() {
        // key = "H" (大寫), targetKey = "h" (小寫) → 應回傳 keyTarget
        let state = KeyState.resolve(key: "H", targetKey: "h", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_uppercaseTargetMapsToLowercaseKey() {
        // key = "h" (小寫), targetKey = "H" (大寫) → 應回傳 keyTarget
        let state = KeyState.resolve(key: "h", targetKey: "H", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_lowercasePressedMapsToUppercaseKey() {
        // key = "A" (大寫), pressedKey = "a" (小寫) → 應回傳 keyPressed
        let state = KeyState.resolve(key: "A", targetKey: "b", pressedKey: "a", errorKey: nil)
        XCTAssertEqual(state, .keyPressed)
    }

    func testResolve_lowercaseErrorMapsToUppercaseKey() {
        // key = "T" (大寫), errorKey = "t" (小寫) → 應回傳 keyError
        let state = KeyState.resolve(key: "T", targetKey: "y", pressedKey: nil, errorKey: "t")
        XCTAssertEqual(state, .keyError)
    }

    func testResolve_errorBeatsTarget_caseInsensitive() {
        // errorKey = "a" (小寫), targetKey = "A" (大寫) → error 優先
        let state = KeyState.resolve(key: "A", targetKey: "A", pressedKey: nil, errorKey: "a")
        XCTAssertEqual(state, .keyError)
    }

    // MARK: - Punctuation/Space Exact Match (Not Lowercased)
    func testResolve_spaceExactMatch() {
        // 空白必須 exact match，不能將 " " 與其他字元混淆
        let state = KeyState.resolve(key: " ", targetKey: " ", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_spaceNotMatchOther() {
        // 空白不應匹配其他字元
        let state = KeyState.resolve(key: " ", targetKey: "a", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyDefault)
    }

    func testResolve_punctuationExactMatch() {
        // 標點符號必須 exact match
        let state = KeyState.resolve(key: ",", targetKey: ",", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_punctuationNotMatchOther() {
        // 標點不應與字母混淆（例如 "," 不應匹配 "c"）
        let state = KeyState.resolve(key: ",", targetKey: "c", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyDefault)
    }

    func testResolve_punctuationCaseSensitive() {
        // 標點大小寫不同（例如 ":" 與 ";" 不同）
        let state = KeyState.resolve(key: ":", targetKey: ";", pressedKey: nil, errorKey: nil)
        XCTAssertEqual(state, .keyDefault)
    }

    // MARK: - Mixed Cases
    func testResolve_allUppercaseKeys() {
        // 全部大寫應該正常運作
        let state = KeyState.resolve(key: "A", targetKey: "A", pressedKey: "B", errorKey: "C")
        XCTAssertEqual(state, .keyTarget)
    }

    func testResolve_allLowercaseKeys() {
        // 全部小寫應該正常運作
        let state = KeyState.resolve(key: "a", targetKey: "a", pressedKey: "b", errorKey: "c")
        XCTAssertEqual(state, .keyTarget)
    }
}