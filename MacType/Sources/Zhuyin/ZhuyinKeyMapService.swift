import Foundation

/// 注音鍵位映射服務
final class ZhuyinKeyMapService: ObservableObject {
    /// symbol → key mapping
    @Published private(set) var symbolToKey: [ZhuyinSymbol: String] = [:]

    /// key → symbol mapping
    @Published private(set) var keyToSymbol: [String: ZhuyinSymbol] = [:]

    /// 指定 bundle（便於測試注入）
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        loadMap()
    }

    // MARK: - 載入
    private func loadMap() {
        guard let url = bundle.url(forResource: "zhuyin_keymap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            // fallback: 使用內嵌標準 mapping
            loadEmbedded()
            return
        }
        var s2k: [ZhuyinSymbol: String] = [:]
        var k2s: [String: ZhuyinSymbol] = [:]
        for (sym, key) in decoded {
            let zhuyin = ZhuyinSymbol(sym)
            s2k[zhuyin] = key
            k2s[key] = zhuyin
        }
        symbolToKey = s2k
        keyToSymbol = k2s
    }

    private func loadEmbedded() {
        symbolToKey = ZhuyinStandardMap.symbolToKey
        keyToSymbol = ZhuyinStandardMap.keyToSymbol
    }

    // MARK: - 查詢
    /// 查詢指定注音對應的鍵位
    func key(for symbol: ZhuyinSymbol) -> String? {
        symbolToKey[symbol]
    }

    /// 查詢指定鍵位對應的注音
    func symbol(for key: String) -> ZhuyinSymbol? {
        keyToSymbol[key]
    }

    /// 回傳所有已知注音
    func allSymbols() -> [ZhuyinSymbol] {
        Array(symbolToKey.keys)
    }

    /// 回傳所有已知鍵
    func allKeys() -> [String] {
        Array(keyToSymbol.keys)
    }

    /// 回傳符號總數
    var count: Int { symbolToKey.count }
}

// MARK: - 測試用工廠
extension ZhuyinKeyMapService {
    /// 用內嵌標準 mapping 建立（不依賴 JSON bundle，測試用）
    static func fromStandard() -> ZhuyinKeyMapService {
        let service = ZhuyinKeyMapService(bundle: .main)
        service.symbolToKey = ZhuyinStandardMap.symbolToKey
        service.keyToSymbol = ZhuyinStandardMap.keyToSymbol
        return service
    }
}
