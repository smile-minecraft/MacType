import Foundation

/// 弱指訓練目標枚舉（僅支援四種指定訓練目標）
enum WeakFingerTarget: String, CaseIterable, Identifiable {
    case leftPinky = "leftPinky"
    case leftRing = "leftRing"
    case rightRing = "rightRing"
    case rightPinky = "rightPinky"

    var id: String { rawValue }

    /// 顯示名稱（中文）
    var displayName: String {
        switch self {
        case .leftPinky:  return "左小指"
        case .leftRing:   return "左無名指"
        case .rightRing:  return "右無名指"
        case .rightPinky: return "右小指"
        }
    }

    /// 顯示名稱（英文）
    var displayNameEn: String {
        switch self {
        case .leftPinky:  return "Left Pinky"
        case .leftRing:   return "Left Ring"
        case .rightRing:  return "Right Ring"
        case .rightPinky: return "Right Pinky"
        }
    }

    /// 對應的 Finger
    var finger: Finger {
        Finger(rawValue: rawValue) ?? .leftPinky
    }

    /// 該手指負責的目標鍵集合（小寫字串）
    var targetKeys: Set<String> {
        switch self {
        case .leftPinky:
            return Set(["a", "q", "z"])
        case .leftRing:
            return Set(["s", "w", "x"])
        case .rightRing:
            return Set(["o", "l", "."])
        case .rightPinky:
            return Set(["p", ";", "?"])
        }
    }
}