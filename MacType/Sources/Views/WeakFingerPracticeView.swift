import SwiftUI

struct WeakFingerPracticeView: View {
    // ==== 狀態 ====
    @State private var selectedTarget: WeakFingerTarget? = nil
    @State private var isPracticeActive: Bool = false
    @StateObject private var engine = WeakFingerPracticeEngine()
    @EnvironmentObject var statsStore: StatsStore
    @State private var showResult: Bool = false
    @State private var lastPressedKey: String? = nil
    @State private var lastErrorKey: String? = nil
    @State private var lessonText: String = ""
    @State private var selectedFatigueScore: Int = 3
    @State private var currentResult: WeakFingerResult? = nil
    @State private var sessionStartTime: Date = Date()
    @State private var currentResultRecorded: Bool = false

    var body: some View {
        ZStack {
            // 透明的全域鍵盤捕捉層
            KeyboardCaptureView(
                onKeyDown: handleKeyDown,
                onBackspace: handleBackspace
            )
            .allowsHitTesting(false)

            if showResult {
                resultView
            } else if isPracticeActive {
                practiceView
            } else {
                targetSelectorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .focusable()
    }

    // MARK: - 目標選擇畫面
    private var targetSelectorView: some View {
        VStack(spacing: 24) {
            Text("Weak Finger Practice")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("選擇訓練手指")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(WeakFingerTarget.allCases) { target in
                    targetCard(target)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 20)
    }

    private func targetCard(_ target: WeakFingerTarget) -> some View {
        VStack(spacing: 12) {
            Text(target.displayName)
                .font(.headline)
            Text(target.displayNameEn)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(target.targetKeys.joined(separator: " / "))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            startPractice(with: target)
        }
    }

    // MARK: - 練習畫面
    private var practiceView: some View {
        VStack(spacing: 24) {
            // 頂部提示
            HStack {
                if let target = selectedTarget {
                    Label("\(target.displayName) (\(target.displayNameEn))", systemImage: "hand.tap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("结束練習") {
                    endPracticeEarly()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

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

            Text("開始打字練習...")
                .foregroundStyle(.secondary)
                .font(.caption)

            Button("Restart") {
                restartPractice()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - 結果畫面
    private var resultView: some View {
        VStack(spacing: 24) {
            Text("練習完成！")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let result = currentResult {
                VStack(spacing: 16) {
                    resultRow(label: "正確率", value: String(format: "%.1f%%", result.accuracy))
                    resultRow(label: "平均反應時間", value: String(format: "%.3f 秒", result.averageReactionTime))
                    resultRow(label: "總擊鍵", value: "\(result.totalKeystrokes)")
                    resultRow(label: "正確擊鍵", value: "\(result.correctKeystrokes)")
                    resultRow(label: "錯誤次數", value: "\(result.errorCount)")
                }
                .padding(20)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)

                // 錯誤鍵統計
                if !result.errorKeys.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("錯誤鍵統計")
                            .font(.headline)
                        ForEach(result.errorKeys.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                            HStack {
                                Text("'\(key)'")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(count) 次")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)
                }

                // 疲勞分數
                VStack(spacing: 12) {
                    Text("疲勞分數")
                        .font(.headline)
                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { score in
                            fatigueButton(score: score)
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Button("更換目標") {
                    changeTarget()
                }
                .buttonStyle(.bordered)

                Button("再次練習") {
                    restartPractice()
                }
                .buttonStyle(.borderedProminent)
            }
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

    private func fatigueButton(score: Int) -> some View {
        Button("\(score)") {
            selectedFatigueScore = score
            engine.fatigueScore = score
        }
        .buttonStyle(.bordered)
        .tint(selectedFatigueScore == score ? .blue : .gray)
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
        let target = lessonText

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
            statItem(label: "進度", value: "\(engine.currentIndex)/\(engine.targetText.count)")
            statItem(label: "錯誤", value: "\(engine.errors.count)")
            statItem(label: "平均反應", value: reactionTimeDisplay)
        }
    }

    private var reactionTimeDisplay: String {
        guard engine.correctKeystrokes > 1 else { return "--" }
        let timestamps = extractReactionTimestamps()
        guard !timestamps.isEmpty else { return "--" }
        let avg = timestamps.reduce(0, +) / Double(timestamps.count)
        return String(format: "%.3fs", avg)
    }

    private func extractReactionTimestamps() -> [Double] {
        // 從 engine 取得反應時間（engine 內部記錄）
        // 這裡用 engine.reactionTimestamps 不在Published，需另闢徑
        // 改由 engine.getResult() 提供
        let result = engine.getResult(for: selectedTarget ?? .leftPinky)
        return [result.averageReactionTime]
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
            Text("最近錯誤 (last \(min(5, engine.errors.count)))")
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
                currentResult = engine.getResult(for: selectedTarget ?? .leftPinky)
                showResult = true
                recordResultIfNeeded()
            }
        }
    }

    private func recordResultIfNeeded() {
        guard !currentResultRecorded, let result = currentResult else { return }
        currentResultRecorded = true
        let endTime = Date()
        statsStore.recordWeakFinger(result: result, startTime: sessionStartTime, endTime: endTime)
    }

    private func handleBackspace() {
        guard !showResult else { return }
        // backspace 在弱指練習中不需要（不後退）
    }

    // MARK: - Actions
    private func startPractice(with target: WeakFingerTarget) {
        selectedTarget = target
        lessonText = LessonGenerator.generate(for: target, length: 30, injectEntropy: 0.3)
        engine.setup(target: target, text: lessonText)
        isPracticeActive = true
        showResult = false
        lastPressedKey = nil
        lastErrorKey = nil
        selectedFatigueScore = 3
    }

    private func endPracticeEarly() {
        // 提前結束練習
        engine.finishEarly()
        currentResult = engine.getResult(for: selectedTarget ?? .leftPinky)
        showResult = true
        recordResultIfNeeded()
    }

    private func restartPractice() {
        guard let target = selectedTarget else { return }
        lessonText = LessonGenerator.generate(for: target, length: 30, injectEntropy: 0.3)
        engine.setup(target: target, text: lessonText)
        showResult = false
        lastPressedKey = nil
        lastErrorKey = nil
        currentResultRecorded = false
        sessionStartTime = Date()
    }

    private func changeTarget() {
        selectedTarget = nil
        isPracticeActive = false
        showResult = false
        engine.reset()
        lastPressedKey = nil
        lastErrorKey = nil
        currentResultRecorded = false
    }
}