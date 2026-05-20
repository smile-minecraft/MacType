import Foundation

/// 鍵盤按鍵模型
struct KeyboardKey: Identifiable, Equatable {
    let id: String       // 唯一識別（通常與顯示字元相同）
    let label: String   // 顯示標籤
    let value: String   // 實際按下的值（供比對用）
    let finger: Finger?
    let width: CGFloat  // 寬度系數（1 = 標準鍵，1.5 = 寬鍵如 Space）

    init(label: String, value: String? = nil, finger: Finger? = nil, width: CGFloat = 1.0) {
        self.label = label
        self.value = value ?? label
        self.id = value ?? label
        self.finger = finger
        self.width = width
    }

    /// 比對此鍵是否對應指定字元（同時支援大小寫）
    func matches(_ char: String) -> Bool {
        value == char || value.lowercased() == char.lowercased()
    }
}