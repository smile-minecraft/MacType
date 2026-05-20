import XCTest
@testable import MacType

final class KeyNormalizerTests: XCTestCase {

    // MARK: - Normalize: 一般英文字母
    func testNormalize_lowercaseLetters() {
        XCTAssertEqual(KeyNormalizer.normalize("a"), "a")
        XCTAssertEqual(KeyNormalizer.normalize("z"), "z")
    }

    func testNormalize_uppercaseLetters() {
        XCTAssertEqual(KeyNormalizer.normalize("A"), "A")
        XCTAssertEqual(KeyNormalizer.normalize("Z"), "Z")
    }

    func testNormalize_mixedCase() {
        XCTAssertEqual(KeyNormalizer.normalize("T"), "T")
        XCTAssertEqual(KeyNormalizer.normalize("h"), "h")
    }

    // MARK: - Normalize: 空白
    func testNormalize_space() {
        XCTAssertEqual(KeyNormalizer.normalize(" "), " ")
    }

    func testNormalize_punctuation() {
        XCTAssertEqual(KeyNormalizer.normalize("."), ".")
        XCTAssertEqual(KeyNormalizer.normalize(","), ",")
        XCTAssertEqual(KeyNormalizer.normalize("!"), "!")
        XCTAssertEqual(KeyNormalizer.normalize("?"), "?")
    }

    // MARK: - Normalize: 控制鍵（應忽略）
    func testNormalize_ignoresControlKeys() {
        XCTAssertNil(KeyNormalizer.normalize("Shift"))
        XCTAssertNil(KeyNormalizer.normalize("Control"))
        XCTAssertNil(KeyNormalizer.normalize("Option"))
        XCTAssertNil(KeyNormalizer.normalize("Command"))
        XCTAssertNil(KeyNormalizer.normalize("CapsLock"))
        XCTAssertNil(KeyNormalizer.normalize("Escape"))
    }

    func testNormalize_ignoresFunctionKeys() {
        XCTAssertNil(KeyNormalizer.normalize("F1"))
        XCTAssertNil(KeyNormalizer.normalize("F12"))
    }

    func testNormalize_ignoresNavigationKeys() {
        XCTAssertNil(KeyNormalizer.normalize("ArrowUp"))
        XCTAssertNil(KeyNormalizer.normalize("ArrowDown"))
        XCTAssertNil(KeyNormalizer.normalize("ArrowLeft"))
        XCTAssertNil(KeyNormalizer.normalize("ArrowRight"))
        XCTAssertNil(KeyNormalizer.normalize("Home"))
        XCTAssertNil(KeyNormalizer.normalize("End"))
        XCTAssertNil(KeyNormalizer.normalize("PageUp"))
        XCTAssertNil(KeyNormalizer.normalize("PageDown"))
    }

    func testNormalize_ignoresEditingKeys() {
        XCTAssertNil(KeyNormalizer.normalize("Backspace"))
        XCTAssertNil(KeyNormalizer.normalize("Delete"))
        XCTAssertNil(KeyNormalizer.normalize("Tab"))
        XCTAssertNil(KeyNormalizer.normalize("Return"))
        XCTAssertNil(KeyNormalizer.normalize("Enter"))
    }

    // MARK: - NormalizeAll
    func testNormalizeAll_batch() {
        let inputs = ["a", "Shift", "b", "F1", " "]
        let results = KeyNormalizer.normalizeAll(inputs)
        XCTAssertEqual(results[0], "a")
        XCTAssertNil(results[1])
        XCTAssertEqual(results[2], "b")
        XCTAssertNil(results[3])
        XCTAssertEqual(results[4], " ")
    }

    // MARK: - NormalizeArrowKey
    func testNormalizeArrowKey_arrows() {
        XCTAssertEqual(KeyNormalizer.normalizeArrowKey("ArrowUp"), "↑")
        XCTAssertEqual(KeyNormalizer.normalizeArrowKey("ArrowDown"), "↓")
        XCTAssertEqual(KeyNormalizer.normalizeArrowKey("ArrowLeft"), "←")
        XCTAssertEqual(KeyNormalizer.normalizeArrowKey("ArrowRight"), "→")
    }

    func testNormalizeArrowKey_nonArrow_returnsNil() {
        XCTAssertNil(KeyNormalizer.normalizeArrowKey("a"))
        XCTAssertNil(KeyNormalizer.normalizeArrowKey("Escape"))
    }
}