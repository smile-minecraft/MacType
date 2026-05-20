import Foundation

/// 注音符號（元音/輔音/聲調統一）
struct ZhuyinSymbol: Hashable, Codable, ExpressibleByStringLiteral {
    let symbol: String

    init(_ symbol: String) {
        self.symbol = symbol
    }

    init(stringLiteral: String) {
        self.symbol = stringLiteral
    }

    var displayText: String { symbol }
}

/// 符號類別（用於分組/過濾）
enum ZhuyinCategory: String, CaseIterable {
    case initial      // 聲母（ㄅㄆㄇㄈㄉ...）
    case medial       // 介音（ㄧㄨㄩ）
    case final_       // 韻母（ㄚㄛㄜ...）
    case tone         // 聲調（ˊˇˋ˙）
}

/// 標準注音鍵位對應表（直接內嵌，不依賴 JSON）
enum ZhuyinStandardMap {
    /// 37 個標準注音符號 → 鍵位 mapping
    static let symbolToKey: [ZhuyinSymbol: String] = [
        ZhuyinSymbol("ㄅ"): "1", ZhuyinSymbol("ㄉ"): "2",
        ZhuyinSymbol("ˇ"): "3", ZhuyinSymbol("ˋ"): "4",
        ZhuyinSymbol("ㄓ"): "5", ZhuyinSymbol("ˊ"): "6",
        ZhuyinSymbol("˙"): "7",
        ZhuyinSymbol("ㄚ"): "8", ZhuyinSymbol("ㄞ"): "9",
        ZhuyinSymbol("ㄢ"): "0", ZhuyinSymbol("ㄦ"): "-",
        ZhuyinSymbol("ㄆ"): "q", ZhuyinSymbol("ㄊ"): "w",
        ZhuyinSymbol("ㄍ"): "e", ZhuyinSymbol("ㄐ"): "r",
        ZhuyinSymbol("ㄔ"): "t", ZhuyinSymbol("ㄗ"): "y",
        ZhuyinSymbol("ㄧ"): "u", ZhuyinSymbol("ㄛ"): "i",
        ZhuyinSymbol("ㄟ"): "o", ZhuyinSymbol("ㄣ"): "p",
        ZhuyinSymbol("ㄇ"): "a", ZhuyinSymbol("ㄋ"): "s",
        ZhuyinSymbol("ㄎ"): "d", ZhuyinSymbol("ㄑ"): "f",
        ZhuyinSymbol("ㄕ"): "g", ZhuyinSymbol("ㄘ"): "h",
        ZhuyinSymbol("ㄨ"): "j", ZhuyinSymbol("ㄜ"): "k",
        ZhuyinSymbol("ㄠ"): "l", ZhuyinSymbol("ㄤ"): ";",
        ZhuyinSymbol("ㄈ"): "z", ZhuyinSymbol("ㄌ"): "x",
        ZhuyinSymbol("ㄏ"): "c", ZhuyinSymbol("ㄒ"): "v",
        ZhuyinSymbol("ㄖ"): "b", ZhuyinSymbol("ㄙ"): "n",
        ZhuyinSymbol("ㄩ"): "m", ZhuyinSymbol("ㄝ"): ",",
        ZhuyinSymbol("ㄡ"): ".", ZhuyinSymbol("ㄥ"): "/"
    ]

    /// 反向 mapping（鍵位 → 符號）
    static let keyToSymbol: [String: ZhuyinSymbol] = {
        Dictionary(uniqueKeysWithValues: symbolToKey.map { ($0.value, $0.key) })
    }()

    /// 所有符號集合（標準鍵盤順序）
    static var allSymbols: [ZhuyinSymbol] {
        orderedSymbols
    }

    /// 標準鍵盤順序的符號陣列（1→0→-→q→w→e→r→t→y→u→i→o→p→a→s→d→f→g→h→j→k→l→;→z→x→c→v→b→n→m→,→.）
    private static let orderedSymbols: [ZhuyinSymbol] = {
        let keyOrder = ["1","2","3","4","5","6","7","8","9","0","-",
                        "q","w","e","r","t","y","u","i","o","p",
                        "a","s","d","f","g","h","j","k","l",";",
                        "z","x","c","v","b","n","m",",","."]
        return keyOrder.compactMap { keyToSymbol[$0] }
    }()

    /// 聲母子集（用於單符號練習）
    static let initials: [ZhuyinSymbol] = [
        ZhuyinSymbol("ㄅ"), ZhuyinSymbol("ㄆ"), ZhuyinSymbol("ㄇ"),
        ZhuyinSymbol("ㄈ"), ZhuyinSymbol("ㄉ"), ZhuyinSymbol("ㄊ"),
        ZhuyinSymbol("ㄋ"), ZhuyinSymbol("ㄌ"), ZhuyinSymbol("ㄍ"),
        ZhuyinSymbol("ㄎ"), ZhuyinSymbol("ㄏ"), ZhuyinSymbol("ㄐ"),
        ZhuyinSymbol("ㄑ"), ZhuyinSymbol("ㄒ"), ZhuyinSymbol("ㄓ"),
        ZhuyinSymbol("ㄔ"), ZhuyinSymbol("ㄕ"), ZhuyinSymbol("ㄖ"),
        ZhuyinSymbol("ㄗ"), ZhuyinSymbol("ㄘ"), ZhuyinSymbol("ㄙ")
    ]

    /// 韻母子集
    static let finals: [ZhuyinSymbol] = [
        ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ"), ZhuyinSymbol("ㄜ"),
        ZhuyinSymbol("ㄝ"), ZhuyinSymbol("ㄞ"), ZhuyinSymbol("ㄟ"),
        ZhuyinSymbol("ㄠ"), ZhuyinSymbol("ㄡ"), ZhuyinSymbol("ㄢ"),
        ZhuyinSymbol("ㄣ"), ZhuyinSymbol("ㄤ"), ZhuyinSymbol("ㄥ"),
        ZhuyinSymbol("ㄦ")
    ]

    /// 介音（medial）
    static let medials: [ZhuyinSymbol] = [
        ZhuyinSymbol("ㄧ"), ZhuyinSymbol("ㄨ"), ZhuyinSymbol("ㄩ")
    ]
}