import Foundation

/// 將鍵盤事件正規化為可比較字元的正規化器
enum KeyNormalizer {
    /// 忽略的可忽略按鍵集（控制鍵、功能鍵等）
    private static let ignorableKeys: Set<String> = [
        "CapsLock", "Shift", "Control", "Option", "Command",
        "Return", "Enter", "Tab", "Escape", "Backspace",
        "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
        "Home", "End", "PageUp", "PageDown",
        "Insert", "Delete", "ForwardDelete",
        "F1", "F2", "F3", "F4", "F5", "F6",
        "F7", "F8", "F9", "F10", "F11", "F12",
        "Help", "VolumeUp", "VolumeDown", "VolumeMute",
        "BrightnessUp", "BrightnessDown", "MissionControl",
        "LaunchPad", "Rewind", "FastForward"
    ]

    /// 將 keyDown 字元正規化為可比較字元
    /// - Parameter input: 未加工的 keyDown 字元（可能來自 NSEvent 或直接字元）
    /// - Returns: 正規化後的字元，若為可忽略按鍵則回傳 nil
    static func normalize(_ input: String) -> String? {
        // 若是可忽略的控制鍵，回傳 nil
        if ignorableKeys.contains(input) {
            return nil
        }

        // 一般可見字元直接回傳
        if let scalar = input.unicodeScalars.first, scalar.isASCII {
            // 檢查是否為控制字元（但非空白）
            if input >= " " || input == " " {
                return input
            }
        }

        // 處理非 ASCII 但可顯示的字元（如少數語系鍵盤產生的裝飾鍵）
        if input.isEmpty == false {
            return input
        }

        return nil
    }

    /// 將游標按鍵轉換為標準箭頭符號
    static func normalizeArrowKey(_ input: String) -> String? {
        switch input {
        case "ArrowUp": return "↑"
        case "ArrowDown": return "↓"
        case "ArrowLeft": return "←"
        case "ArrowRight": return "→"
        default: return nil
        }
    }

    /// 批次正規化（用於測試）
    static func normalizeAll(_ inputs: [String]) -> [String?] {
        inputs.map { normalize($0) }
    }
}