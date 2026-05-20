import SwiftUI

struct EnglishPracticeView: View {
    @StateObject private var engine = PracticeEngine()
    @EnvironmentObject var statsStore: StatsStore
    @State private var showResult: Bool = false
    @State private var lastPressedKey: String? = nil
    @State private var lastErrorKey: String? = nil
    @State private var currentResultRecorded: Bool = false
    @State private var sessionStartTime: Date = Date()

    var body: some View {
        ZStack {
            // 透明的全域鍵盤捕捉層（置於最底，VStack 之上）
            KeyboardCaptureView(
                onKeyDown: handleKeyDown,
                onBackspace: handleBackspace
            )
            .allowsHitTesting(false)

            // 前景內容
            if showResult {
                resultView
            } else {
                practiceView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .focusable() // 確保視圖可接收 focus
    }

    // MARK: - Practice View
    private var practiceView: some View {
        VStack(spacing: 24) {
            Text("English Practice")
                .font(.largeTitle)
                .fontWeight(.bold)

            targetTextDisplay

            Divider()

            statsBar

            if !engine.errors.isEmpty {
                errorList
            }

            Spacer()

            // 虛擬鍵盤
            KeyboardView(
                targetKey: engine.getCurrentChar(),
                pressedKey: lastPressedKey,
                errorKey: lastErrorKey
            )

            Spacer()

            Text("Start typing to begin...")
                .foregroundStyle(.secondary)
                .font(.caption)

            Button("Restart") {
                restart()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Result View
    private var resultView: some View {
        VStack(spacing: 24) {
            Text("Practice Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let result = engine.getResult() {
                VStack(spacing: 16) {
                    resultRow(label: "WPM", value: String(format: "%.1f", result.wpm))
                    resultRow(label: "Accuracy", value: String(format: "%.1f%%", result.accuracy))
                    resultRow(label: "Total Keystrokes", value: "\(result.totalKeystrokes)")
                    resultRow(label: "Correct Keystrokes", value: "\(result.correctKeystrokes)")
                    resultRow(label: "Errors", value: "\(result.errorCount)")
                    resultRow(label: "Duration", value: String(format: "%.1fs", result.durationSeconds))
                }
                .padding(20)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)

                if !result.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error Details")
                            .font(.headline)
                        ForEach(result.errors.prefix(10)) { error in
                            HStack {
                                Text("[\(error.index)]")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text("expected: '\(error.targetChar)'")
                                Text("got: '\(error.actualChar)'")
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)
                }
            }

            Button("Try Again") {
                restart()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Target Text Display
    private var targetTextDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target:")
                .font(.caption)
                .foregroundStyle(.secondary)

            targetTextWithHighlights
                .font(.title2)
                .fontDesign(.monospaced)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var targetTextWithHighlights: Text {
        var result = Text("")
        let target = engine.targetText

        for (i, char) in target.enumerated() {
            let str = String(char)
            if i < engine.currentIndex {
                result = result + Text(str).foregroundColor(.green)
            } else if i == engine.currentIndex {
                result = result + Text(str).foregroundColor(.blue).underline()
            } else {
                result = result + Text(str).foregroundColor(.primary)
            }
        }
        return result
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 24) {
            statItem(label: "Progress", value: "\(engine.currentIndex)/\(engine.targetText.count)")
            statItem(label: "Errors", value: "\(engine.errors.count)")
            statItem(label: "Started", value: engine.hasStarted ? "Yes" : "No")
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error List
    private var errorList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Errors (last \(min(5, engine.errors.count)))")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(engine.errors.suffix(5)) { error in
                HStack(spacing: 12) {
                    Text("[\(error.index)]")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("'\(error.targetChar)'")
                        .foregroundColor(.green)
                    Text("→")
                    Text("'\(error.actualChar)'")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Key Handling
    private func handleKeyDown(_ char: String) {
        guard !showResult else { return }
        if !engine.hasStarted {
            sessionStartTime = Date()
        }
        if let normalized = KeyNormalizer.normalize(char) {
            lastPressedKey = normalized
            let isCorrect = engine.processInput(normalized)
            if !isCorrect {
                lastErrorKey = normalized
            } else {
                lastErrorKey = nil
            }
            if engine.isFinished {
                showResult = true
                recordResultIfNeeded()
            }
        }
    }

    private func recordResultIfNeeded() {
        guard !currentResultRecorded else { return }
        currentResultRecorded = true
        if let result = engine.getResult() {
            let endTime = Date()
            statsStore.recordEnglish(result: result, startTime: sessionStartTime, endTime: endTime)
        }
    }

    private func handleBackspace() {
        guard !showResult else { return }
        engine.handleBackspace()
    }

    private func restart() {
        engine.reset()
        showResult = false
        lastPressedKey = nil
        lastErrorKey = nil
        currentResultRecorded = false
        sessionStartTime = Date()
    }
}