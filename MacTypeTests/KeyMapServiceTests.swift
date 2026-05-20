import XCTest
@testable import MacType

final class KeyMapServiceTests: XCTestCase {

    // MARK: - Static Factory
    func testFromStatic_returnsService() {
        let service = KeyMapService.fromStatic()
        XCTAssertNotNil(service)
    }

    func testFromStatic_fingerLookup_lowercase() {
        let service = KeyMapService.fromStatic()
        XCTAssertEqual(service.finger(for: "a"), .leftPinky)
        XCTAssertEqual(service.finger(for: "s"), .leftRing)
        XCTAssertEqual(service.finger(for: "d"), .leftMiddle)
        XCTAssertEqual(service.finger(for: "f"), .leftIndex)
        XCTAssertEqual(service.finger(for: "j"), .rightIndex)
        XCTAssertEqual(service.finger(for: "k"), .rightMiddle)
        XCTAssertEqual(service.finger(for: "l"), .rightRing)
        XCTAssertEqual(service.finger(for: ";"), .rightMiddle)
    }

    func testFromStatic_fingerLookup_space() {
        let service = KeyMapService.fromStatic()
        XCTAssertEqual(service.finger(for: " "), .thumb)
    }

    func testFromStatic_fingerLookup_punctuation() {
        let service = KeyMapService.fromStatic()
        XCTAssertEqual(service.finger(for: "."), .rightRing)
        XCTAssertEqual(service.finger(for: ","), .rightMiddle)
        XCTAssertEqual(service.finger(for: "?"), .rightRing)
    }

    func testFromStatic_fingerLookup_unknown() {
        let service = KeyMapService.fromStatic()
        XCTAssertNil(service.finger(for: "~"))
    }

    // MARK: - Color Lookup
    func testColorLookup_returnsValidRGB() {
        let service = KeyMapService.fromStatic()
        let color = service.color(for: "f")
        XCTAssertNotNil(color)
        XCTAssertGreaterThanOrEqual(color?.red ?? 0, 0)
        XCTAssertLessThanOrEqual(color?.red ?? 0, 1)
    }

    func testColorLookup_unknownKey_returnsNil() {
        let service = KeyMapService.fromStatic()
        XCTAssertNil(service.color(for: "~"))
    }

    // MARK: - All Mapped Keys
    func testAllMappedKeys_returnsNonEmpty() {
        let service = KeyMapService.fromStatic()
        XCTAssertFalse(service.allMappedKeys().isEmpty)
    }
}