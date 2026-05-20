---
type: plan-content
contentVersion: 8
planId: mactype-mvp
projectId: mactype
projectPath: /Volumes/Smile-Data/MainData/Project-Nest/MacType
title: "Mactype MVP 開發計畫"
updatedAt: 2026-05-20T08:19:26.289Z
---








# MacType MVP 開發計畫

## 目標
建立 macOS 原生 SwiftUI 打字練習 App。MVP 聚焦每天可用、低干擾、能記錄弱點、能針對弱點產生練習內容；不做登入、雲端、排行榜、完整中文輸入法、Electron/Tauri 或大型遊戲化。

## 命名規範
- 產品與 App 顯示名稱一律使用：MacType。
- 任務 ID / plan ID 可維持既有小寫 slug：mactype-*，僅作內部識別。

## 技術與產品邊界
- 技術：SwiftUI macOS App，最低 macOS 14+（可視開發環境調整為 15+）。
- 儲存：Application Support 下本地 JSON（sessions.json、mistakes.json、daily_stats.json、settings.json）。MVP 不導入 SwiftData / migration。
- App 架構：Sidebar + Content View，預設 Dashboard。
- Raw Key Mode：English / Weak Finger / Zhuyin Key Practice 皆直接處理 keyDown，不依賴文字輸入框。
- 中文實戰輸入：僅預留，不納入 MVP。

## MVP 完成定義
1. App 可正常啟動。
2. Sidebar 可切換主要頁面。
3. 英文盲打模式可完成一段練習。
4. 英文練習可顯示 WPM、Accuracy、Mistakes。
5. 虛擬鍵盤可顯示目前目標鍵。
6. 弱指訓練可針對指定手指生成練習。
7. 注音鍵位模式可進行單一符號練習。
8. 練習結果可儲存到本地 JSON。
9. Dashboard 可顯示今日練習摘要。
10. 關閉 App 後重新開啟，統計資料仍存在。

## 依賴圖摘要
- Phase 1 → Phase 2 → Phase 3
- Phase 2 → Phase 4
- Phase 2 → Phase 5
- Phase 2 + Phase 4 + Phase 5 → Phase 6

## 任務拆解

### task: mactype-phase-1-skeleton
<!-- task-anchor: mactype-phase-1-skeleton -->



#### 執行紀錄（Phase 1）
- 實作：建立 MacType SwiftUI macOS App 骨架，使用 XcodeGen 產生 `MacType.xcodeproj`。
- 新增 Sidebar + Detail 架構，預設 Dashboard。
- 新增 6 個 placeholder 頁面：Dashboard、English Practice、Weak Finger Practice、Zhuyin Key Practice、Stats、Settings。
- 驗證：`xcodegen generate && xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build` → `** BUILD SUCCEEDED **`。
- 審查：momus 同意 / 通過；無阻斷問題。非阻斷建議：Phase 2 起補最小測試 target / CI build 固化。

### task: mactype-phase-2-english-core
<!-- task-anchor: mactype-phase-2-english-core -->



### Phase 2 執行紀錄（2026-05-19）

實作完成英文練習核心：
- 新增 `MacType/Sources/Practice/KeyNormalizer.swift`：一般字元正規化與控制/功能/導航鍵忽略。
- 新增 `MacType/Sources/Practice/PracticeEngine.swift`：逐字輸入狀態、錯誤記錄、游標推進、reset、simulate 測試輔助。
- 新增 `MacType/Sources/Practice/PracticeResult.swift`：WPM、Accuracy、Error count、完成判定。
- 新增 `MacType/Sources/Practice/TypingErrorRecord.swift`：index、targetChar、actualChar、timestamp 與唯一 UI id。
- 新增 `MacType/Sources/Views/TypingTextField.swift`：macOS `NSViewRepresentable` keyDown 捕捉層。
- 修改 `MacType/Sources/Views/EnglishPracticeView.swift`：替換 placeholder，顯示目標句、進度、近期錯誤、完成結果（WPM / Accuracy / Errors / Duration）與 Restart/Try Again。
- 修改 `project.yml`：新增 `MacTypeTests` unit-test target。
- 新增 `MacTypeTests/KeyNormalizerTests.swift` 與 `MacTypeTests/PracticeEngineTests.swift`。

驗證命令（主代理親自執行）：
```bash
xcodegen generate && \
xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build && \
xcodebuild -project "MacType.xcodeproj" -scheme "MacTypeTests" -configuration Debug test
```

Green 證明：
- `Created project at /Volumes/Smile-Data/MainData/Project-Nest/MacType/MacType.xcodeproj`
- `** BUILD SUCCEEDED **`
- `** TEST SUCCEEDED **`
- 總計 `Executed 35 tests, with 0 failures (0 unexpected)`。

Momus G4：
- 初審不通過，阻斷：`PracticeResult.isComplete` 有錯誤即 true、缺少未完成但有錯誤測試；非阻斷建議修正 `TypingErrorRecord.id` 重複風險。
- 已由 debugger 修正：`isComplete = correctKeystrokes >= targetText.count`；新增 5 個 `testIsComplete_*` 測試；`TypingErrorRecord.id` 改為 `index + timestamp`。
- 複審結論：`同意 / 通過`，Phase 2 可進入 ARCHIVING。

殘留非阻斷風險：
- `KeyboardCaptureView` 依賴 macOS first responder，需後續實機手動驗收；目前 build/unit tests 通過。
- `TypingErrorRecord.id` 使用 `index + timestamp` 理論上仍有極低碰撞可能；如後續遇到 List diff 問題可改 UUID 或 monotonic counter。
### task: mactype-phase-3-keyboard
<!-- task-anchor: mactype-phase-3-keyboard -->



### Phase 3 執行紀錄（2026-05-20）

實作完成虛擬鍵盤：
- 新增 `MacType/Resources/finger_keymap.json`：key -> finger 對應表，包含 a-z/A-Z、space 與常用標點。
- 新增 `MacType/Sources/Keyboard/Finger.swift`：手指分類與顏色定義。
- 新增 `MacType/Sources/Keyboard/KeyboardKey.swift`：虛擬鍵模型。
- 新增 `MacType/Sources/Keyboard/KeyboardLayout.swift`：QWERTY 三列 + Space layout，含 `, . ?`。
- 新增 `MacType/Sources/Keyboard/KeyMapService.swift`：載入 finger map，查詢 key/finger/color。
- 新增 `MacType/Sources/Keyboard/KeyState.swift`：狀態解析純函式，優先權為錯誤 > 目標 > 剛按下 > 預設；英文字母大小寫視為同一實體鍵，空白/標點 exact match。
- 新增 `MacType/Sources/Views/KeyboardView.swift`：SwiftUI 虛擬鍵盤 UI，依 state 與 finger color 呈現。
- 修改 `MacType/Sources/Views/EnglishPracticeView.swift`：整合 `KeyboardView`，傳入 `engine.getCurrentChar()`、`lastPressedKey`、`lastErrorKey`，按鍵輸入時更新狀態。
- 新增 `MacTypeTests/KeyMapServiceTests.swift` 與 `MacTypeTests/KeyStateTests.swift`。

主代理發現並修復問題：
- 初版使用大寫虛擬鍵值與小寫 target/pressed/error exact match，導致小寫字母不會高亮。
- 已由 debugger 修復 `KeyState.resolve`，對英文字母採大小寫不敏感匹配；新增相關大小寫、space、punctuation 測試。

驗證命令（主代理親自執行）：
```bash
xcodegen generate && \
xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build && \
xcodebuild -project "MacType.xcodeproj" -scheme "MacTypeTests" -configuration Debug test
```

Green 證明：
- `** BUILD SUCCEEDED **`
- `** TEST SUCCEEDED **`
- 總計 `Executed 67 tests, with 0 failures (0 unexpected)`。

Momus G4：
- 審查結論：`同意 / 通過`。
- Momus 確認 `KeyState.resolve` 優先序、大小寫匹配、space/punctuation exact match、`KeyboardView` 狀態色、`EnglishPracticeView` 整合與 `finger_keymap.json` 納入 Resources。

殘留非阻斷風險：
- `KeyMapServiceTests` 主要透過 `fromStatic()` 測試查詢邏輯，未直接驗證 runtime bundle 載入 JSON；momus 判定非阻斷，建議後續可補整合測試。
- `lastPressedKey` / `lastErrorKey` 目前不自動 timer 清除，會持續到下一個有效 key；符合 Phase 3 MVP 驗收。
### task: mactype-phase-4-weak-finger
<!-- task-anchor: mactype-phase-4-weak-finger -->



### Phase 4 執行紀錄（2026-05-20）
- 狀態：已完成實作並通過 G4 momus 審查。
- 實作內容：新增 WeakFingerTarget、LessonGenerator、WeakFingerResult、WeakFingerPracticeEngine，替換 WeakFingerPracticeView placeholder，整合 KeyboardCaptureView 與 KeyboardView。
- UI：可選左小指、左無名指、右無名指、右小指；練習時顯示目標字串、進度、錯誤、平均反應、虛擬鍵盤目標/按下/錯誤高亮；結果頁顯示正確率、平均反應時間、錯誤鍵統計、疲勞分數 1–5。
- 修復紀錄：
  - 修復 `WeakFingerPracticeView` 直接寫入 `engine.isFinished` 的 private(set) 編譯錯誤，改由 `WeakFingerPracticeEngine.finishEarly()` 提前結束。
  - 修復 `LessonGenerator.generateDeterministic` 不同 seed 產生相同結果的測試失敗，改用 xorshift PRNG。
- 測試：新增 WeakFingerTargetTests、LessonGeneratorTests、WeakFingerPracticeEngineTests。
- Green 證明：執行 `xcodegen generate && xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build && xcodebuild -project "MacType.xcodeproj" -scheme "MacTypeTests" -configuration Debug test`，結果 `BUILD SUCCEEDED`、`TEST SUCCEEDED`，`Executed 105 tests, with 0 failures (0 unexpected)`。
- Momus 結論：同意 / 通過。非阻斷建議：後續可排序 LessonGenerator target keys 以提高 deterministic 跨環境一致性；移除或修正無參數 `getResult()` 預設 leftPinky 的誤用風險；調整 reaction time helper 命名。

### task: mactype-phase-5-zhuyin
<!-- task-anchor: mactype-phase-5-zhuyin -->



### Phase 5 執行紀錄（2026-05-20）
- 狀態：已完成實作並通過 G4 momus 複審。
- 實作內容：新增 `zhuyin_keymap.json`、ZhuyinSymbol/ZhuyinStandardMap、ZhuyinKeyMapService、ZhuyinLessonGenerator、ZhuyinPracticeEngine、ZhuyinPracticeResult，替換 ZhuyinKeyPracticeView placeholder。
- UI：可選 Single Symbol / Syllable 與 Sequential / Random；練習時顯示目前注音符號/音節、答錯提示、統計、最近錯誤、注音鍵盤 target/pressed/error 高亮；結果頁顯示正確率、正確/錯誤次數、題目數、耗時、模式/順序、錯誤統計與 Word Hint 預留區。
- 修復紀錄：
  - 修復 `ZhuyinPracticeEngineTests` force unwrap crash：single symbol 答對會自動前進，測試移除額外 `advanceToNextQuestion()` 並改用安全 unwrap。
  - 修復 momus 阻斷：`ZhuyinKeyPracticeView.startPractice()` 會先呼叫 `engine.configure(mode: selectedMode, order: selectedOrder)`，確保 result metadata 反映 UI 選擇。
  - 修復 `ZhuyinPracticeResult.keyErrorStats` 改統計 `actualChar`；`progress` 完成後 clamp；`ZhuyinStandardMap.allSymbols` 改固定 `orderedSymbols`；Phase 4 `LessonGenerator` target keys 改 `.sorted()` 消除 deterministic 不穩。
- 測試：新增/更新 ZhuyinKeyMapServiceTests、ZhuyinLessonGeneratorTests、ZhuyinPracticeEngineTests，並修復相關回歸測試。
- Green 證明：執行 `xcodegen generate && xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build && xcodebuild -project "MacType.xcodeproj" -scheme "MacTypeTests" -configuration Debug test`，結果 `BUILD SUCCEEDED`、`TEST SUCCEEDED`，`Executed 145 tests, with 0 failures (0 unexpected)`。
- Momus 結論：初審不通過（mode/order 未綁定 engine）；修復後複審同意 / 通過。非阻斷建議：後續可加測 orderedSymbols 順序與鍵位序列 1:1 對照。

### task: mactype-phase-6-stats-storage
<!-- task-anchor: mactype-phase-6-stats-storage -->



## Phase 6 執行紀錄（2026-05-20）

### 完成內容
- 新增本地統計/儲存模組：`PracticeSessionRecord`、`DashboardSummary`、`StatsSummary`、`ModeStats`、`FileStore`、`StatsStore`。
- `FileStore` 預設使用 Application Support/MacType/sessions.json；讀寫失敗以 console print fallback，不 crash；支援測試注入 `baseURL`，並在寫入前自動建立父目錄。
- `StatsStore` 啟動時載入 sessions，新增 session 後自動 persist；提供英文、弱指、注音三種結果記錄轉換；提供 Dashboard/Stats summary。
- `MacTypeApp` 注入全域 `StatsStore` environment object。
- `EnglishPracticeView`、`WeakFingerPracticeView`、`ZhuyinKeyPracticeView` 完成練習時寫入統計，並以 record-once guard 避免同一結果重複寫入。
- `DashboardView` 改為真實資料：今日練習次數、今日練習時間、平均正確率、總錯誤、最常錯鍵、弱指重點、最近練習。
- `StatsView` 改為真實資料：總 session、總練習時間、總錯誤、總擊鍵、平均正確率、各模式統計、錯誤鍵排行、最近 session。
- 新增 `StatsTests.swift` 覆蓋 FileStore round-trip、malformed/missing fallback、nonexistent baseURL auto-create directory、StatsStore persist/reload、Dashboard summary、top error keys、三種模式 conversion、reset。

### 驗證
主代理執行：
```bash
xcodegen generate && xcodebuild -project "MacType.xcodeproj" -scheme "MacType" -configuration Debug build && xcodebuild -project "MacType.xcodeproj" -scheme "MacTypeTests" -configuration Debug test
```
結果：`BUILD SUCCEEDED`、`TEST SUCCEEDED`，`Executed 157 tests, with 0 failures (0 unexpected)`。

### Momus G4
- Momus 初審結論：同意 / 通過，僅建議補強 FileStore baseURL 目錄建立。
- 已依建議補強 FileStore 寫入前建立父目錄，並新增測試；最終 157 tests 全綠。

### 殘留限制
- JSON schema 尚無版本/migration；後續若擴充欄位需補 migration 策略。
- 讀寫錯誤目前只 console print，尚未做使用者可見提示。
- 實際 Application Support persistence 仍建議以手動完成練習、關閉重啟 App 驗證。
