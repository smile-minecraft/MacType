import XCTest
@testable import MacType

final class ZhuyinLessonGeneratorTests: XCTestCase {
    // MARK: - Single Symbol Sequential
    func test_single_symbol_sequential_is_stable() {
        let q1 = ZhuyinLessonGenerator.generateSingleSymbol(count: 5, seed: nil)
        let q2 = ZhuyinLessonGenerator.generateSingleSymbol(count: 5, seed: nil)
        XCTAssertEqual(q1.map(\.displayText), q2.map(\.displayText))
    }

    func test_single_symbol_sequential_count() {
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 10, seed: nil)
        XCTAssertEqual(questions.count, 10)
    }

    func test_single_symbol_sequential_each_has_one_symbol() {
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 20, seed: nil)
        for q in questions {
            XCTAssertEqual(q.symbols.count, 1, "Each question should have exactly 1 symbol: \(q.displayText)")
        }
    }

    func test_single_symbol_sequential_all_symbols_in_standard_map() {
        let questions = ZhuyinLessonGenerator.generateSingleSymbol(count: 37, seed: nil)
        for q in questions {
            XCTAssertFalse(
                ZhuyinStandardMap.symbolToKey[q.symbols[0]] == nil,
                "Symbol not in standard map: \(q.displayText)"
            )
        }
    }

    // MARK: - Single Symbol Random (Seeded)
    func test_single_symbol_random_seed_is_deterministic() {
        let q1 = ZhuyinLessonGenerator.generateSingleSymbol(count: 10, seed: 12345)
        let q2 = ZhuyinLessonGenerator.generateSingleSymbol(count: 10, seed: 12345)
        XCTAssertEqual(q1.map(\.displayText), q2.map(\.displayText))
    }

    func test_single_symbol_random_different_seeds_differ() {
        let q1 = ZhuyinLessonGenerator.generateSingleSymbol(count: 10, seed: 12345)
        let q2 = ZhuyinLessonGenerator.generateSingleSymbol(count: 10, seed: 67890)
        XCTAssertNotEqual(q1.map(\.displayText), q2.map(\.displayText))
    }

    // MARK: - Syllable
    func test_syllable_questions_have_valid_length() {
        let questions = ZhuyinLessonGenerator.generateSyllable(count: 20, seed: nil)
        for q in questions {
            XCTAssertGreaterThanOrEqual(q.symbols.count, 1, "Syllable should have at least 1 symbol")
            XCTAssertLessThanOrEqual(q.symbols.count, 3, "Syllable should have at most 3 symbols")
        }
    }

    func test_syllable_all_symbols_in_standard_map() {
        let questions = ZhuyinLessonGenerator.generateSyllable(count: 30, seed: nil)
        for q in questions {
            for sym in q.symbols {
                XCTAssertNotNil(
                    ZhuyinStandardMap.symbolToKey[sym],
                    "Symbol not in standard map: \(sym.displayText) in question \(q.displayText)"
                )
            }
        }
    }

    func test_syllable_random_seed_is_deterministic() {
        let q1 = ZhuyinLessonGenerator.generateSyllable(count: 10, seed: 999)
        let q2 = ZhuyinLessonGenerator.generateSyllable(count: 10, seed: 999)
        XCTAssertEqual(q1.map(\.displayText), q2.map(\.displayText))
    }

    func test_syllable_count() {
        let questions = ZhuyinLessonGenerator.generateSyllable(count: 15, seed: nil)
        XCTAssertEqual(questions.count, 15)
    }

    // MARK: - Generate (mode/order factory)
    func test_generate_single_symbol_sequential() {
        let questions = ZhuyinLessonGenerator.generate(
            mode: .singleSymbol,
            order: .sequential,
            count: 5,
            seed: nil
        )
        XCTAssertEqual(questions.count, 5)
        for q in questions {
            XCTAssertEqual(q.symbols.count, 1)
        }
    }

    func test_generate_syllable_random_with_seed() {
        let questions = ZhuyinLessonGenerator.generate(
            mode: .syllable,
            order: .random,
            count: 10,
            seed: 777
        )
        XCTAssertEqual(questions.count, 10)
    }
}