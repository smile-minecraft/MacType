import Foundation

/// 弱指練習文句生成器
enum LessonGenerator {
    /// 生成指定目標的練習字串
    /// - Parameters:
    ///   - target: 訓練目標
    ///   - length: 目標字串長度（預設 30）
    ///   - injectEntropy: 額外注入隨機性（0.0~1.0，預設 0.3），會隨機摻入鄰近鍵或空隔
    /// - Returns: 練習用字串
    static func generate(
        for target: WeakFingerTarget,
        length: Int = 30,
        injectEntropy: Double = 0.3
    ) -> String {
        let keys = Array(target.targetKeys).sorted()
        guard !keys.isEmpty else { return "" }

        var result: [String] = []
        var lastKey: String = ""
        var secondLastKey: String = ""
        var thirdLastKey: String = ""
        var attempts = 0
        let maxAttempts = length * 8 // 防死循環

        while result.count < length && attempts < maxAttempts {
            attempts += 1

            let r = Double.random(in: 0...1)

            if r < injectEntropy {
                // 注入空白或分隔
                if r < injectEntropy / 2 {
                    // 空白（放鬆）
                    if result.last != " " {
                        result.append(" ")
                        lastKey = ""
                        secondLastKey = ""
                        thirdLastKey = ""
                    }
                    continue
                }
            }

            // 隨機選擇一個目標鍵
            let chosen = keys.randomElement() ?? keys[0]

            // ==== 避免同一鍵連續超過 3 次 ====
            // 檢查是否會形成三連：chosen == lastKey == secondLastKey
            let willBeTriple = (chosen == lastKey && lastKey == secondLastKey)

            if chosen == thirdLastKey || willBeTriple {
                // 跳過，嘗試其他鍵
                if let alternative = keys.first(where: { $0 != chosen }) {
                    // 避免該鍵導致新的連續 3 次
                    // 檢查 alternative 是否會與 lastKey + secondLastKey 形成三連
                    let altWillBeTriple = (alternative == lastKey && lastKey == secondLastKey)
                    if altWillBeTriple {
                        // 再試，找不與 lastKey 形成三連的鍵
                        if let alternative2 = keys.first(where: { $0 != chosen && $0 != lastKey }) {
                            result.append(alternative2)
                            thirdLastKey = secondLastKey
                            secondLastKey = lastKey
                            lastKey = alternative2
                        } else {
                            continue
                        }
                    } else {
                        result.append(alternative)
                        thirdLastKey = secondLastKey
                        secondLastKey = lastKey
                        lastKey = alternative
                    }
                } else {
                    continue
                }
            } else {
                result.append(chosen)
                thirdLastKey = secondLastKey
                secondLastKey = lastKey
                lastKey = chosen
            }
        }

        return result.joined()
    }

    /// Deterministically generate lesson string using seed (for testing)
    static func generateDeterministic(
        for target: WeakFingerTarget,
        length: Int = 30,
        seed: UInt64 = 42
    ) -> String {
        let keys = Array(target.targetKeys).sorted()
        guard !keys.isEmpty else { return "" }

        // Xorshift PRNG - 更好的隨機性與更長週期
        var state = seed
        func nextRandom() -> Double {
            var x = state
            x ^= x &<< 13
            x ^= x &>> 7
            x ^= x &<< 17
            state = x
            // 轉換為 0~1 的 Double
            return Double(bitPattern: 0x3FF0000000000000 | (x &>> 12)) - 1.0
        }

        var result: [String] = []
        var lastKey: String = ""
        var secondLastKey: String = ""
        var thirdLastKey: String = ""

        for _ in 0..<length {
            let chosen = keys[Int(nextRandom() * Double(keys.count))]

            // ==== 避免同一鍵連續超過 3 次 ====
            // 檢查是否會形成三連：chosen == lastKey == secondLastKey
            let willBeTriple = (chosen == lastKey && lastKey == secondLastKey)

            if chosen == thirdLastKey || willBeTriple {
                // 嘗試替換 - 持續嘗試直到找到合適的
                var replaced = false
                for _ in 0..<20 { // 最多嘗試 20 次
                    let alt = keys[Int(nextRandom() * Double(keys.count))]
                    if alt != chosen && !(alt == lastKey && lastKey == secondLastKey) {
                        result.append(alt)
                        thirdLastKey = secondLastKey
                        secondLastKey = lastKey
                        lastKey = alt
                        replaced = true
                        break
                    }
                }
                if !replaced {
                    // 找不到合適的，優先選擇不與 lastKey 相同的鍵
                    // 這減少形成三連的可能性
                    if let alt = keys.first(where: { $0 != chosen && $0 != lastKey }) {
                        result.append(alt)
                        thirdLastKey = secondLastKey
                        secondLastKey = lastKey
                        lastKey = alt
                    } else if let alt = keys.first(where: { $0 != chosen }) {
                        result.append(alt)
                        thirdLastKey = secondLastKey
                        secondLastKey = lastKey
                        lastKey = alt
                    }
                }
            } else {
                result.append(chosen)
                thirdLastKey = secondLastKey
                secondLastKey = lastKey
                lastKey = chosen
            }
        }

        return result.joined()
    }
}