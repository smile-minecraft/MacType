import SwiftUI

struct ZhuyinKeyPracticeView: View {
    @StateObject private var keyMapService = ZhuyinKeyMapService()
    @StateObject private var engine: ZhuyinPracticeEngine
    @EnvironmentObject var statsStore: StatsStore

    @State private var showResult: Bool = false
    @State private var lastPressedKey: String? = nil
    @State private var lastErrorKey: String? = nil
    @State private var selectedMode: ZhuyinPracticeMode = .singleSymbol
    @State private var selectedOrder: ZhuyinQuestionOrder = .sequential
    @State private var isStarted: Bool = false
    @State private var sessionStartTime: Date = Date()
    @State private var currentResultRecorded: Bool = false

    init() {
        _engine = StateObject(wrappedValue: ZhuyinPracticeEngine(mode: .singleSymbol, order: .sequential))
    }

    var body: some View {
        ZStack {
            // 透明的全域鍵盤捕捉層（置於最底）
            KeyboardCaptureView(
                onKeyDown: handleKeyDown,
                onBackspace: { /* 注音練習不支援 backspace */ }
            )
            .allowsHitTesting(false)

            if showResult {
                resultView
            } else if !isStarted {
                configView
            } else {
                practiceView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .focusable()
    }

    // MARK: - Config View
    private var configView: some View {
        VStack(spacing: 24) {
            Text("注音鍵位練習")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                Text("練習模式")
                    .font(.headline)
                Picker("模式", selection: $selectedMode) {
                    ForEach(ZhuyinPracticeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("題目順序")
                    .font(.headline)
                Picker("順序", selection: $selectedOrder) {
                    ForEach(ZhuyinQuestionOrder.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)

            Button("開始練習") {
                startPractice()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Practice View
    private var practiceView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("注音鍵位練習")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(engine.progress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 顯示當前注音符號
            zhuyinDisplay

            // 提示訊息（答錯後顯示）
            if engine.showHint, let expectedKey = engine.currentExpectedKey {
                hintBanner(expectedKey: expectedKey)
            }

            Divider()

            statsBar

            if !engine.errorRecords.isEmpty {
                errorList
            }

            Spacer()

            // 虛擬鍵盤（使用注音鍵位）
            zhuyinKeyboardView

            Spacer()

            Button("結束練習") {
                finishEarly()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Zhuyin Display
    private var zhuyinDisplay: some View {
        VStack(spacing: 12) {
            Text("請按以下注音對應的鍵")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(engine.currentAllSymbols.enumerated()), id: \.offset) { idx, symbol in
                    let isCurrent = idx == engine.currentSymbolIndex
                    let isCompleted = idx < engine.currentSymbolIndex

                    Text(symbol.displayText)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .frame(minWidth: 50, minHeight: 50)
                        .background(backgroundColorForSymbol(isCurrent: isCurrent, isCompleted: isCompleted))
                        .foregroundColor(isCompleted ? .green : (isCurrent ? .white : .primary))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
                        )

                    if idx < engine.currentAllSymbols.count - 1 {
                        Text(" + ")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 顯示每個符號對應的鍵（在 hint 模式下）
            if engine.showHint {
                HStack(spacing: 4) {
                    ForEach(Array(engine.currentAllSymbols.enumerated()), id: \.offset) { idx, symbol in
                        let key = keyMapService.key(for: symbol) ?? "?"
                        Text("[\(key)]")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }

    private func backgroundColorForSymbol(isCurrent: Bool, isCompleted: Bool) -> Color {
        if isCompleted {
            return Color.green.opacity(0.3)
        } else if isCurrent {
            return Color.blue.opacity(0.8)
        } else {
            return Color.primary.opacity(0.08)
        }
    }

    // MARK: - Hint Banner
    private func hintBanner(expectedKey: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("提示：請按「\(expectedKey)」鍵")
                .fontWeight(.medium)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 24) {
            statItem(label: "正確", value: "\(engine.totalCorrect)")
            statItem(label: "錯誤", value: "\(engine.totalErrors)")
            statItem(label: "進度", value: engine.progress)
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
            Text("最近錯誤 (last \(min(5, engine.errorRecords.count)))")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(engine.errorRecords.suffix(5)) { error in
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

    // MARK: - Zhuyin Keyboard View
    private var zhuyinKeyboardView: some View {
        VStack(spacing: 4) {
            // 第一排：數字行
            HStack(spacing: 4) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"], id: \.self) { key in
                    zhuyinKeyButton(key)
                }
            }
            // 第二排：QWERTY 行
            HStack(spacing: 4) {
                ForEach(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], id: \.self) { key in
                    zhuyinKeyButton(key)
                }
            }
            // 第三排：ASDF 行
            HStack(spacing: 4) {
                ForEach(["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"], id: \.self) { key in
                    zhuyinKeyButton(key)
                }
            }
            // 第四排：ZXCV 行
            HStack(spacing: 4) {
                ForEach(["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"], id: \.self) { key in
                    zhuyinKeyButton(key)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    private func zhuyinKeyButton(_ key: String) -> some View {
        let resolvedState = KeyState.resolve(
            key: key,
            targetKey: engine.currentExpectedKey,
            pressedKey: lastPressedKey,
            errorKey: lastErrorKey
        )

        return Text(key)
            .font(.system(size: 12, weight: .medium))
            .frame(width: 32, height: 44)
            .background(backgroundColor(state: resolvedState))
            .foregroundColor(foregroundColor(state: resolvedState))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor(state: resolvedState), lineWidth: resolvedState == .keyDefault ? 0.5 : 1.5)
            )
    }

    private func backgroundColor(state: KeyState) -> Color {
        switch state {
        case .keyError:   return Color.red.opacity(0.7)
        case .keyTarget:  return Color.blue.opacity(0.8)
        case .keyPressed: return Color.blue.opacity(0.45)
        case .keyDefault: return Color.primary.opacity(0.08)
        }
    }

    private func foregroundColor(state: KeyState) -> Color {
        switch state {
        case .keyError, .keyTarget, .keyPressed: return .white
        case .keyDefault: return .primary
        }
    }

    private func borderColor(state: KeyState) -> Color {
        switch state {
        case .keyError:   return .red.opacity(0.8)
        case .keyTarget:  return .blue.opacity(0.9)
        case .keyPressed: return .blue.opacity(0.6)
        case .keyDefault: return .gray.opacity(0.3)
        }
    }

    // MARK: - Result View
    private var resultView: some View {
        VStack(spacing: 24) {
            Text("練習完成！")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let result = engine.getResult() {
                VStack(spacing: 16) {
                    resultRow(label: "正確率", value: String(format: "%.1f%%", result.accuracy))
                    resultRow(label: "正確次數", value: "\(result.totalCorrect)")
                    resultRow(label: "錯誤次數", value: "\(result.totalErrors)")
                    resultRow(label: "題目數", value: "\(result.totalQuestions)")
                    resultRow(label: "耗時", value: String(format: "%.1fs", result.durationSeconds))
                    resultRow(label: "模式", value: result.mode.rawValue)
                    resultRow(label: "順序", value: result.order.rawValue)
                }
                .padding(20)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)

                // 錯誤統計
                let stats = result.errorStats
                if !stats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("錯誤統計（符號 → 次數）")
                            .font(.headline)
                        ForEach(Array(stats.sorted(by: { $0.value > $1.value }).prefix(10)), id: \.key) { sym, count in
                            HStack {
                                Text("\(sym)")
                                    .fontWeight(.medium)
                                Text("× \(count)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)
                }

                // Word Hint 預留
                VStack(spacing: 8) {
                    Text("Word Hint")
                        .font(.headline)
                    Text("完整中文 IME 功能將在 Phase 6 實現")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.05))
                .cornerRadius(8)
            }

            Button("再練一次") {
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

    // MARK: - Key Handling
    private func handleKeyDown(_ char: String) {
        guard !showResult, isStarted else { return }
        if let normalized = KeyNormalizer.normalize(char) {
            lastPressedKey = normalized
            let (isCorrect, _) = engine.processKey(normalized)
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
            statsStore.recordZhuyin(result: result, startTime: sessionStartTime, endTime: endTime)
        }
    }

    // MARK: - Actions
    private func startPractice() {
        // 更新 engine 的 mode/order 與使用者選擇一致
        engine.configure(mode: selectedMode, order: selectedOrder)
        
        let questions = ZhuyinLessonGenerator.generate(
            mode: selectedMode,
            order: selectedOrder,
            seed: selectedOrder == .random ? 42 : nil
        )
        engine.setQuestions(questions)
        isStarted = true
        showResult = false
        lastPressedKey = nil
        lastErrorKey = nil
    }

    private func finishEarly() {
        showResult = true
        recordResultIfNeeded()
    }

    private func restart() {
        engine.reset()
        showResult = false
        isStarted = false
        lastPressedKey = nil
        lastErrorKey = nil
        currentResultRecorded = false
    }
}