import SwiftUI

/// 虛擬鍵盤視圖
struct KeyboardView: View {
    /// 目前練習的目標字元（下一個要按的鍵）
    let targetKey: String?
    /// 剛按下的字元
    let pressedKey: String?
    /// 最後錯誤的字元
    let errorKey: String?
    /// 鍵盤指法映射服務（用於查詢手指分類色）
    @StateObject private var keyMapService = KeyMapService()

    // 鍵之間的間距
    private let keySpacing: CGFloat = 4
    // 鍵的高度
    private let keyHeight: CGFloat = 44

    var body: some View {
        VStack(spacing: keySpacing) {
            // 主鍵盤列（QWERTYUIOP, ASDFGHJKL, ZXCVBNM,.)
            ForEach(Array(KeyboardLayout.mainRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: keySpacing) {
                    ForEach(row) { key in
                        keyButton(for: key)
                    }
                }
            }
            // 空白鍵列
            HStack(spacing: keySpacing) {
                ForEach(KeyboardLayout.bottomRow) { key in
                    keyButton(for: key)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    // MARK: - 單一按鍵
    @ViewBuilder
    private func keyButton(for key: KeyboardKey) -> some View {
        let resolvedState = KeyState.resolve(
            key: key.value,
            targetKey: targetKey,
            pressedKey: pressedKey,
            errorKey: errorKey
        )
        let fingerColor = keyMapService.color(for: key.value)

        Text(key.label)
            .font(.system(size: 14, weight: .medium, design: .default))
            .frame(width: keyWidth(key), height: keyHeight)
            .background(backgroundColor(state: resolvedState, fingerColor: fingerColor))
            .foregroundColor(foregroundColor(state: resolvedState))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor(state: resolvedState), lineWidth: resolvedState == .keyDefault ? 0.5 : 1.5)
            )
    }

    // MARK: - 鍵寬
    private func keyWidth(_ key: KeyboardKey) -> CGFloat {
        let base: CGFloat = 32
        return base * key.width + keySpacing * (key.width - 1)
    }

    // MARK: - 背景色
    private func backgroundColor(state: KeyState, fingerColor: (red: Double, green: Double, blue: Double)?) -> Color {
        switch state {
        case .keyError:
            return Color.red.opacity(0.7)
        case .keyTarget:
            return Color.blue.opacity(0.8)
        case .keyPressed:
            return Color.blue.opacity(0.45)
        case .keyDefault:
            if let fc = fingerColor {
                return Color(red: fc.red, green: fc.green, blue: fc.blue).opacity(0.4)
            }
            return Color.primary.opacity(0.08)
        }
    }

    // MARK: - 前景色
    private func foregroundColor(state: KeyState) -> Color {
        switch state {
        case .keyError:    return .white
        case .keyTarget:   return .white
        case .keyPressed:  return .white
        case .keyDefault:  return .primary
        }
    }

    // MARK: - 邊框色
    private func borderColor(state: KeyState) -> Color {
        switch state {
        case .keyError:    return .red.opacity(0.8)
        case .keyTarget:   return .blue.opacity(0.9)
        case .keyPressed:  return .blue.opacity(0.6)
        case .keyDefault:  return .gray.opacity(0.3)
        }
    }
}