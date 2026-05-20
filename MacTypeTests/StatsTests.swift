import XCTest
@testable import MacType

final class StatsTests: XCTestCase {

    // MARK: - FileStore round-trip

    func testFileStore_roundTrip() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore(fileName: "test_sessions.json")
        store.baseURL = tempDir

        let sessions = [
            PracticeSessionRecord(
                mode: .english,
                date: Date(),
                startTime: Date().addingTimeInterval(-60),
                endTime: Date(),
                durationSeconds: 60,
                accuracy: 95.0,
                wpm: 45.0,
                errorCount: 3,
                totalKeystrokes: 100,
                correctKeystrokes: 97,
                errorKeys: ["a": 1, "b": 2]
            ),
            PracticeSessionRecord(
                mode: .weakFinger,
                date: Date(),
                startTime: Date().addingTimeInterval(-120),
                endTime: Date().addingTimeInterval(-60),
                durationSeconds: 60,
                accuracy: 88.5,
                errorCount: 5,
                totalKeystrokes: 50,
                correctKeystrokes: 45,
                weakFingerTarget: "leftPinky",
                fatigueScore: 3,
                errorKeys: ["q": 3, "a": 2]
            )
        ]

        store.save(sessions)

        let loaded: [PracticeSessionRecord]? = store.load([PracticeSessionRecord].self)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].mode, .english)
        XCTAssertEqual(loaded?[0].accuracy, 95.0)
        XCTAssertEqual(loaded?[1].mode, .weakFinger)
        XCTAssertEqual(loaded?[1].weakFingerTarget, "leftPinky")
    }

    // MARK: - FileStore non-existent baseURL → creates dir + round-trip

    func testFileStore_createsDirectoryForNonExistentBaseURL() {
        // 指向一個「尚不存在」的 deep nested 目錄
        let deepDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("subdir", isDirectory: true)
        try? FileManager.default.removeItem(at: deepDir)

        XCTAssertFalse(FileManager.default.fileExists(atPath: deepDir.path))

        let store = FileStore(fileName: "roundtrip.json")
        store.baseURL = deepDir

        let sessions = [
            PracticeSessionRecord(
                mode: .english,
                date: Date(),
                startTime: Date().addingTimeInterval(-60),
                endTime: Date(),
                durationSeconds: 60,
                accuracy: 92.0,
                wpm: 50.0,
                errorCount: 2,
                totalKeystrokes: 100,
                correctKeystrokes: 98,
                errorKeys: ["k": 2]
            )
        ]

        store.save(sessions)

        // 目錄應已建立
        XCTAssertTrue(FileManager.default.fileExists(atPath: deepDir.path))

        // 重新建立 store（模擬 cold load），從同樣不存在的 baseURL 讀取
        let freshStore = FileStore(fileName: "roundtrip.json")
        freshStore.baseURL = deepDir
        let loaded: [PracticeSessionRecord]? = freshStore.load([PracticeSessionRecord].self)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?[0].mode, .english)
        XCTAssertEqual(loaded?[0].accuracy, 92.0)

        try? FileManager.default.removeItem(at: deepDir.deletingLastPathComponent().deletingLastPathComponent())
    }

    // MARK: - FileStore malformed JSON fallback

    func testFileStore_malformedJSON_returnsNil() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore(fileName: "malformed.json")
        store.baseURL = tempDir

        let malformedData = "{ invalid json }".data(using: .utf8)!
        try? malformedData.write(to: tempDir.appendingPathComponent("malformed.json"))

        let loaded: [PracticeSessionRecord]? = store.load([PracticeSessionRecord].self)
        XCTAssertNil(loaded)
    }

    func testFileStore_missingFile_returnsNil() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore(fileName: "nonexistent.json")
        store.baseURL = tempDir

        let loaded: [PracticeSessionRecord]? = store.load([PracticeSessionRecord].self)
        XCTAssertNil(loaded)
    }

    // MARK: - StatsStore persistence reload

    func testStatsStore_persistsAndReloads() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore()
        store.baseURL = tempDir

        let statsStore = StatsStore(store: store)

        let result = PracticeResult(
            targetText: "hello",
            startTime: Date().addingTimeInterval(-30),
            endTime: Date(),
            errors: [],
            totalKeystrokes: 5,
            correctKeystrokes: 5
        )
        statsStore.recordEnglish(result: result, startTime: Date().addingTimeInterval(-30), endTime: Date())
        XCTAssertEqual(statsStore.sessions.count, 1)

        // Reload
        let reloadStore = StatsStore(store: store)
        XCTAssertEqual(reloadStore.sessions.count, 1)
        XCTAssertEqual(reloadStore.sessions[0].mode, .english)
    }

    // MARK: - Summary 今日統計

    func testDashboardSummary_todayStats() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore()
        store.baseURL = tempDir

        let statsStore = StatsStore(store: store)

        // 寫入兩個今日 session
        let result1 = PracticeResult(
            targetText: "abc",
            startTime: Date().addingTimeInterval(-120),
            endTime: Date().addingTimeInterval(-60),
            errors: [],
            totalKeystrokes: 10,
            correctKeystrokes: 10
        )
        let result2 = PracticeResult(
            targetText: "xyz",
            startTime: Date().addingTimeInterval(-60),
            endTime: Date(),
            errors: [],
            totalKeystrokes: 10,
            correctKeystrokes: 8
        )

        statsStore.recordEnglish(result: result1, startTime: Date().addingTimeInterval(-120), endTime: Date().addingTimeInterval(-60))
        statsStore.recordEnglish(result: result2, startTime: Date().addingTimeInterval(-60), endTime: Date())

        let summary = statsStore.dashboardSummary
        XCTAssertEqual(summary.todaySessionCount, 2)
        XCTAssertEqual(summary.todayTotalErrors, 0) // both complete with 100% accuracy
    }

    func testDashboardSummary_empty() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore()
        store.baseURL = tempDir

        let statsStore = StatsStore(store: store)
        let summary = statsStore.dashboardSummary

        XCTAssertEqual(summary.todaySessionCount, 0)
        XCTAssertEqual(summary.todayTotalSeconds, 0)
    }

    // MARK: - Top mistakes

    func testTopErrorKeys_aggregated() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore()
        store.baseURL = tempDir

        let statsStore = StatsStore(store: store)

        // Session with error keys
        let record = PracticeSessionRecord(
            mode: .english,
            date: Date(),
            startTime: Date().addingTimeInterval(-60),
            endTime: Date(),
            durationSeconds: 60,
            accuracy: 80.0,
            wpm: 40.0,
            errorCount: 5,
            totalKeystrokes: 100,
            correctKeystrokes: 80,
            errorKeys: ["a": 3, "b": 2, "c": 1]
        )
        statsStore.addSession(record)

        let summary = statsStore.statsSummary
        XCTAssertTrue(summary.topErrorKeys.count >= 3)

        let topKey = summary.topErrorKeys.first { $0.key == "a" }
        XCTAssertNotNil(topKey)
        XCTAssertEqual(topKey?.count, 3)
    }

    // MARK: - 各 mode record conversion

    func testRecordEnglish_fromPracticeResult() {
        let result = PracticeResult(
            targetText: "hello",
            startTime: Date().addingTimeInterval(-30),
            endTime: Date(),
            errors: [
                TypingErrorRecord(index: 1, targetChar: "e", actualChar: "x"),
                TypingErrorRecord(index: 3, targetChar: "l", actualChar: "y")
            ],
            totalKeystrokes: 10,
            correctKeystrokes: 8
        )

        let record = PracticeSessionRecord.fromEnglish(result: result, startTime: Date().addingTimeInterval(-30), endTime: Date())

        XCTAssertEqual(record.mode, .english)
        XCTAssertEqual(record.errorCount, 2)
        XCTAssertEqual(record.errorKeys["x"], 1)
        XCTAssertEqual(record.errorKeys["y"], 1)
        XCTAssertNotNil(record.wpm)
    }

    func testRecordWeakFinger_fromWeakFingerResult() {
        let result = WeakFingerResult(
            target: .leftPinky,
            accuracy: 85.0,
            averageReactionTime: 0.5,
            errorKeys: ["q": 5, "a": 3],
            fatigueScore: 2,
            totalKeystrokes: 50,
            correctKeystrokes: 43
        )

        let record = PracticeSessionRecord.fromWeakFinger(result: result, startTime: Date().addingTimeInterval(-60), endTime: Date())

        XCTAssertEqual(record.mode, .weakFinger)
        XCTAssertEqual(record.weakFingerTarget, "leftPinky")
        XCTAssertEqual(record.fatigueScore, 2)
        XCTAssertEqual(record.errorKeys["q"], 5)
        XCTAssertNil(record.wpm)
    }

    func testRecordZhuyin_fromZhuyinPracticeResult() {
        let result = ZhuyinPracticeResult(
            mode: .singleSymbol,
            order: .sequential,
            startTime: Date().addingTimeInterval(-30),
            endTime: Date(),
            totalQuestions: 20,
            totalCorrect: 17,
            totalErrors: 3,
            errorRecords: [
                TypingErrorRecord(index: 0, targetChar: "ㄧ", actualChar: "q"),
                TypingErrorRecord(index: 5, targetChar: "ㄅ", actualChar: "o")
            ],
            wordHintUsed: false
        )

        let record = PracticeSessionRecord.fromZhuyin(result: result, startTime: Date().addingTimeInterval(-30), endTime: Date())

        XCTAssertEqual(record.mode, .zhuyin)
        XCTAssertEqual(record.errorCount, 3)
        XCTAssertEqual(record.errorKeys["q"], 1)
        XCTAssertEqual(record.errorKeys["o"], 1)
    }

    // MARK: - StatsStore reset

    func testStatsStore_reset() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = FileStore()
        store.baseURL = tempDir

        let statsStore = StatsStore(store: store)

        let result = PracticeResult(
            targetText: "test",
            startTime: Date(),
            endTime: Date(),
            errors: [],
            totalKeystrokes: 4,
            correctKeystrokes: 4
        )
        statsStore.recordEnglish(result: result, startTime: Date(), endTime: Date())
        XCTAssertEqual(statsStore.sessions.count, 1)

        statsStore.reset()
        XCTAssertEqual(statsStore.sessions.count, 0)
    }
}