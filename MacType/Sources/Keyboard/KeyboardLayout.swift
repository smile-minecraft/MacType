import Foundation

/// QWERTY 鍵盤佈局
enum KeyboardLayout {
    /// QWERTY 三列主鍵盤 + 常用符號
    static let mainRows: [[KeyboardKey]] = [
        // 第一列：QWERTYUIOP
        [
            KeyboardKey(label: "Q", finger: .leftPinky),
            KeyboardKey(label: "W", finger: .leftRing),
            KeyboardKey(label: "E", finger: .leftMiddle),
            KeyboardKey(label: "R", finger: .leftIndex),
            KeyboardKey(label: "T", finger: .leftIndex),
            KeyboardKey(label: "Y", finger: .rightIndex),
            KeyboardKey(label: "U", finger: .rightIndex),
            KeyboardKey(label: "I", finger: .rightMiddle),
            KeyboardKey(label: "O", finger: .rightRing),
            KeyboardKey(label: "P", finger: .rightPinky)
        ],
        // 第二列：ASDFGHJKL
        [
            KeyboardKey(label: "A", finger: .leftPinky),
            KeyboardKey(label: "S", finger: .leftRing),
            KeyboardKey(label: "D", finger: .leftMiddle),
            KeyboardKey(label: "F", finger: .leftIndex),
            KeyboardKey(label: "G", finger: .leftIndex),
            KeyboardKey(label: "H", finger: .rightIndex),
            KeyboardKey(label: "J", finger: .rightIndex),
            KeyboardKey(label: "K", finger: .rightMiddle),
            KeyboardKey(label: "L", finger: .rightRing)
        ],
        // 第三列：ZXCVBNM + 常用符號
        [
            KeyboardKey(label: "Z", finger: .leftPinky),
            KeyboardKey(label: "X", finger: .leftRing),
            KeyboardKey(label: "C", finger: .leftMiddle),
            KeyboardKey(label: "V", finger: .leftIndex),
            KeyboardKey(label: "B", finger: .leftIndex),
            KeyboardKey(label: "N", finger: .rightIndex),
            KeyboardKey(label: "M", finger: .rightIndex),
            KeyboardKey(label: ",", finger: .rightMiddle),
            KeyboardKey(label: ".", finger: .rightRing),
            KeyboardKey(label: "?", finger: .rightRing)
        ]
    ]

    /// 空白鍵列
    static let bottomRow: [KeyboardKey] = [
        KeyboardKey(label: "Space", value: " ", finger: .thumb, width: 5.0)
    ]

    /// 所有鍵（平面列表）
    static var allKeys: [KeyboardKey] {
        mainRows.flatMap { $0 } + bottomRow
    }

    /// 所有可顯示字元（供狀態解析用）
    static var allChars: [String] {
        allKeys.map { $0.value }
    }
}