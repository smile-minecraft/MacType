import Foundation

/// 鍵盤指法映射服務
final class KeyMapService: ObservableObject {
    /// finger map（從 JSON 載入）
    var fingerMap: [String: Finger] = [:]

    /// 指定 bundle（便於測試注入）
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        loadFingerMap()
    }

    // MARK: - 載入
    private func loadFingerMap() {
        guard let url = bundle.url(forResource: "finger_keymap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        for (key, fingerStr) in decoded {
            if let finger = Finger(rawValue: fingerStr) {
                fingerMap[key] = finger
            }
        }
    }

    // MARK: - 查詢
    /// 查詢指定字元對應的手指
    func finger(for key: String) -> Finger? {
        // 先嘗試直接比對
        if let f = fingerMap[key] { return f }
        // 再嘗試忽略大小寫
        if let f = fingerMap[key.uppercased()] { return f }
        if let f = fingerMap[key.lowercased()] { return f }
        return nil
    }

    /// 查詢指定字元對應的手指顏色（RGB 元組）
    func color(for key: String) -> (red: Double, green: Double, blue: Double)? {
        guard let f = finger(for: key) else { return nil }
        return f.color
    }

    /// 查詢鍵盤上所有已知鍵
    func allMappedKeys() -> [String] {
        Array(fingerMap.keys)
    }
}

// MARK: - 測試用工廠
extension KeyMapService {
    /// 用已知的 static map 建立（不依賴 JSON，測試用）
    static func fromStatic() -> KeyMapService {
        let service = KeyMapService(bundle: .main)
        // 手工注入測試用 static map
        let staticMap: [String: Finger] = [
            "a": Finger.leftPinky, "s": Finger.leftRing, "d": Finger.leftMiddle, "f": Finger.leftIndex,
            "g": Finger.leftIndex, "h": Finger.rightIndex, "j": Finger.rightIndex, "k": Finger.rightMiddle,
            "l": Finger.rightRing, "q": Finger.leftPinky, "w": Finger.leftRing, "e": Finger.leftMiddle,
            "r": Finger.leftIndex, "t": Finger.leftIndex, "y": Finger.rightIndex, "u": Finger.rightIndex,
            "i": Finger.rightMiddle, "o": Finger.rightRing, "p": Finger.rightPinky,
            "z": Finger.leftPinky, "x": Finger.leftRing, "c": Finger.leftMiddle, "v": Finger.leftIndex,
            "b": Finger.leftIndex, "n": Finger.rightIndex, "m": Finger.rightIndex,
            " ": Finger.thumb, ".": Finger.rightRing, ",": Finger.rightMiddle, "?": Finger.rightRing,
            "!": Finger.rightPinky, "'": Finger.rightPinky, ";": Finger.rightMiddle
        ]
        service.fingerMap = staticMap
        return service
    }
}