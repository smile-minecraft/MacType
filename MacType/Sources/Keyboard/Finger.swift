import Foundation

/// 手指分類枚舉
enum Finger: String, Codable, CaseIterable {
    case leftPinky = "leftPinky"
    case leftRing = "leftRing"
    case leftMiddle = "leftMiddle"
    case leftIndex = "leftIndex"
    case rightIndex = "rightIndex"
    case rightMiddle = "rightMiddle"
    case rightRing = "rightRing"
    case rightPinky = "rightPinky"
    case thumb = "thumb"

    /// 手指分類顏色（用於 UI 高亮）
    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .leftPinky:  return (0.85, 0.60, 0.85)  // 淡紫
        case .leftRing:   return (0.60, 0.75, 0.85)  // 淡藍
        case .leftMiddle: return (0.60, 0.85, 0.75)  // 淡青
        case .leftIndex:  return (0.70, 0.85, 0.60)  // 淡綠
        case .rightIndex: return (0.85, 0.85, 0.60)  // 淡黃
        case .rightMiddle:return (0.90, 0.75, 0.60)  // 淡橙
        case .rightRing:  return (0.95, 0.65, 0.55)  // 淡紅
        case .rightPinky: return (0.85, 0.55, 0.70)  // 淡粉
        case .thumb:      return (0.75, 0.75, 0.75)  // 灰
        }
    }
}