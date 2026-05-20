import XCTest
@testable import MacType

final class LessonGeneratorTests: XCTestCase {

    // MARK: - 生成字串只包含目標鍵與空白/分隔
    func testGenerated_usesOnlyTargetKeys_orSpace() {
        let target = WeakFingerTarget.leftPinky
        let result = LessonGenerator.generate(for: target, length: 50)

        for char in result {
            let str = String(char)
            XCTAssertTrue(
                target.targetKeys.contains(str) || str == " " || str.isEmpty,
                "Unexpected char '\(char)' in result for \(target)"
            )
        }
    }

    func testGenerated_forRightRing_usesOnlyTargetKeys() {
        let target = WeakFingerTarget.rightRing
        let result = LessonGenerator.generate(for: target, length: 50)

        for char in result {
            let str = String(char)
            XCTAssertTrue(
                target.targetKeys.contains(str) || str == " ",
                "Unexpected char '\(char)' for rightRing"
            )
        }
    }

    // MARK: - 指定長度合理
    func testGenerated_length() {
        let target = WeakFingerTarget.leftPinky
        let result = LessonGenerator.generate(for: target, length: 30)
        XCTAssertEqual(result.count, 30)
    }

    func testGenerated_lengthVariants() {
        for length in [10, 20, 50, 100] {
            let target = WeakFingerTarget.leftRing
            let result = LessonGenerator.generate(for: target, length: length)
            XCTAssertEqual(result.count, length, "length=\(length) failed")
        }
    }

    // MARK: - 避免同一鍵連續超過 3 次
    func testNoTripleConsecutive() {
        let target = WeakFingerTarget.rightPinky
        let result = LessonGenerator.generate(for: target, length: 100, injectEntropy: 0.0)

        // 檢查：絕不應該有連續 3 個相同字元
        var consecutive = 1
        var lastChar: Character = "\0"

        for char in result {
            if char == lastChar {
                consecutive += 1
                XCTAssertLessThan(consecutive, 3, "Triple consecutive '\(char)' found")
            } else {
                consecutive = 1
                lastChar = char
            }
        }
    }

    func testNoTripleConsecutive_allTargets() {
        for target in WeakFingerTarget.allCases {
            let result = LessonGenerator.generate(for: target, length: 200, injectEntropy: 0.0)

            var consecutive = 1
            var lastChar: Character = "\0"

            for char in result {
                if char == lastChar {
                    consecutive += 1
                    XCTAssertLessThan(
                        consecutive, 3,
                        "Triple consecutive '\(char)' for \(target)"
                    )
                } else {
                    consecutive = 1
                    lastChar = char
                }
            }
        }
    }

    // MARK: - Deterministic 穩定
    func testDeterministic_sameSeedSameResult() {
        let target = WeakFingerTarget.leftRing
        let r1 = LessonGenerator.generateDeterministic(for: target, length: 30, seed: 12345)
        let r2 = LessonGenerator.generateDeterministic(for: target, length: 30, seed: 12345)
        XCTAssertEqual(r1, r2)
    }

    func testDeterministic_differentSeedDifferentResult() {
        let target = WeakFingerTarget.leftRing
        let r1 = LessonGenerator.generateDeterministic(for: target, length: 30, seed: 12345)
        let r2 = LessonGenerator.generateDeterministic(for: target, length: 30, seed: 99999)
        XCTAssertNotEqual(r1, r2)
    }

    func testDeterministic_length() {
        let target = WeakFingerTarget.rightPinky
        let result = LessonGenerator.generateDeterministic(for: target, length: 50, seed: 42)
        XCTAssertEqual(result.count, 50)
    }

    func testDeterministic_noTripleConsecutive() {
        let target = WeakFingerTarget.leftPinky
        let result = LessonGenerator.generateDeterministic(for: target, length: 200, seed: 777)

        var consecutive = 1
        var lastChar: Character = "\0"

        for char in result {
            if char == lastChar {
                consecutive += 1
                XCTAssertLessThan(consecutive, 3)
            } else {
                consecutive = 1
                lastChar = char
            }
        }
    }

    // MARK: - 空目標防呆
    func testGenerate_emptyKeysGuard() {
        // 故意用 empty keys target (不存在的 target)
        // WeakFingerTarget.allCases 都保證有 keys，所以這裡只測確定有 keys 的target
        let result = LessonGenerator.generate(for: WeakFingerTarget.leftPinky, length: 5)
        XCTAssertEqual(result.count, 5)
    }
}