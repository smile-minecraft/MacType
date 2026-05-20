import XCTest
@testable import MacType

final class ZhuyinKeyMapServiceTests: XCTestCase {
    var service: ZhuyinKeyMapService!

    override func setUp() {
        super.setUp()
        service = ZhuyinKeyMapService.fromStandard()
    }

    // MARK: - 符號 → 鍵查詢
    func test_ㄅ_maps_to_1() {
        let sym = ZhuyinSymbol("ㄅ")
        XCTAssertEqual(service.key(for: sym), "1")
    }

    func test_ㄆ_maps_to_q() {
        let sym = ZhuyinSymbol("ㄆ")
        XCTAssertEqual(service.key(for: sym), "q")
    }

    func test_ㄧ_maps_to_u() {
        let sym = ZhuyinSymbol("ㄧ")
        XCTAssertEqual(service.key(for: sym), "u")
    }

    func test_ㄩ_maps_to_m() {
        let sym = ZhuyinSymbol("ㄩ")
        XCTAssertEqual(service.key(for: sym), "m")
    }

    func test_ㄥ_maps_to_slash() {
        let sym = ZhuyinSymbol("ㄥ")
        XCTAssertEqual(service.key(for: sym), "/")
    }

    // MARK: - 鍵 → 符號查詢
    func test_key_1_maps_to_ㄅ() {
        XCTAssertEqual(service.symbol(for: "1"), ZhuyinSymbol("ㄅ"))
    }

    func test_key_q_maps_to_ㄆ() {
        XCTAssertEqual(service.symbol(for: "q"), ZhuyinSymbol("ㄆ"))
    }

    func test_key_u_maps_to_ㄧ() {
        XCTAssertEqual(service.symbol(for: "u"), ZhuyinSymbol("ㄧ"))
    }

    func test_key_m_maps_to_ㄩ() {
        XCTAssertEqual(service.symbol(for: "m"), ZhuyinSymbol("ㄩ"))
    }

    func test_key_slash_maps_to_ㄥ() {
        XCTAssertEqual(service.symbol(for: "/"), ZhuyinSymbol("ㄥ"))
    }

    // MARK: - 無效查詢
    func test_unknown_symbol_returns_nil() {
        let sym = ZhuyinSymbol("invalid")
        XCTAssertNil(service.key(for: sym))
    }

    func test_unknown_key_returns_nil() {
        XCTAssertNil(service.symbol(for: "?"))
    }

    // MARK: - allSymbols
    func test_allSymbols_count_is_at_least_37() {
        let symbols = service.allSymbols()
        XCTAssertGreaterThanOrEqual(symbols.count, 37)
    }

    func test_allSymbols_contains_all_standard_symbols() {
        let symbols = service.allSymbols()
        let mustHave: [ZhuyinSymbol] = [
            ZhuyinSymbol("ㄅ"), ZhuyinSymbol("ㄆ"), ZhuyinSymbol("ㄇ"),
            ZhuyinSymbol("ㄈ"), ZhuyinSymbol("ㄉ"), ZhuyinSymbol("ㄧ"),
            ZhuyinSymbol("ㄨ"), ZhuyinSymbol("ㄩ"), ZhuyinSymbol("ㄦ")
        ]
        for sym in mustHave {
            XCTAssertTrue(symbols.contains(sym), "Missing: \(sym.displayText)")
        }
    }

    // MARK: - 反向一致性
    func test_all_keys_roundtrip() {
        let keys = service.allKeys()
        for key in keys {
            if let sym = service.symbol(for: key) {
                XCTAssertEqual(service.key(for: sym), key)
            }
        }
    }
}