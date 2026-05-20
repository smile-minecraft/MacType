import XCTest
@testable import MacType

final class WeakFingerTargetTests: XCTestCase {

    // MARK: - 四個 target 存在
    func testAllCases_count() {
        XCTAssertEqual(WeakFingerTarget.allCases.count, 4)
    }

    func testAllCases_names() {
        let names = WeakFingerTarget.allCases.map { $0.rawValue }
        XCTAssertTrue(names.contains("leftPinky"))
        XCTAssertTrue(names.contains("leftRing"))
        XCTAssertTrue(names.contains("rightRing"))
        XCTAssertTrue(names.contains("rightPinky"))
    }

    // MARK: - finger 映射正確
    func testLeftPinky_fingerMapping() {
        XCTAssertEqual(WeakFingerTarget.leftPinky.finger, .leftPinky)
    }

    func testLeftRing_fingerMapping() {
        XCTAssertEqual(WeakFingerTarget.leftRing.finger, .leftRing)
    }

    func testRightRing_fingerMapping() {
        XCTAssertEqual(WeakFingerTarget.rightRing.finger, .rightRing)
    }

    func testRightPinky_fingerMapping() {
        XCTAssertEqual(WeakFingerTarget.rightPinky.finger, .rightPinky)
    }

    // MARK: - target keys 非空且符合預期
    func testLeftPinky_targetKeys() {
        let keys = WeakFingerTarget.leftPinky.targetKeys
        XCTAssertFalse(keys.isEmpty)
        XCTAssertTrue(keys.contains("a"))
    }

    func testLeftRing_targetKeys() {
        let keys = WeakFingerTarget.leftRing.targetKeys
        XCTAssertFalse(keys.isEmpty)
        XCTAssertTrue(keys.contains("s"))
    }

    func testRightRing_targetKeys() {
        let keys = WeakFingerTarget.rightRing.targetKeys
        XCTAssertFalse(keys.isEmpty)
        XCTAssertTrue(keys.contains("o") || keys.contains("l"))
    }

    func testRightPinky_targetKeys() {
        let keys = WeakFingerTarget.rightPinky.targetKeys
        XCTAssertFalse(keys.isEmpty)
        XCTAssertTrue(keys.contains("p"))
    }

    // MARK: - displayName 非空
    func testAllTargets_haveDisplayName() {
        for target in WeakFingerTarget.allCases {
            XCTAssertFalse(target.displayName.isEmpty)
            XCTAssertFalse(target.displayNameEn.isEmpty)
        }
    }

    // MARK: - id 一致性
    func testAllTargets_idMatchesRawValue() {
        for target in WeakFingerTarget.allCases {
            XCTAssertEqual(target.id, target.rawValue)
        }
    }
}