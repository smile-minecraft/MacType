import Foundation

/// 注音練習題目產生器
enum ZhuyinLessonGenerator {
    /// 產生單符號練習題目
    /// - Parameters:
    ///   - count: 題目數量（預設全部 37 個）
    ///   - symbols: 要練習的符號集合（預設全部）
    ///   - seed: 隨機種子（為 nil 時使用 order=sequential）
    /// - Returns: 題目陣列
    static func generateSingleSymbol(
        count: Int? = nil,
        symbols: [ZhuyinSymbol]? = nil,
        seed: UInt64? = nil
    ) -> [ZhuyinQuestion] {
        let pool = symbols ?? ZhuyinStandardMap.allSymbols
        guard !pool.isEmpty else { return [] }

        let allQuestions: [ZhuyinQuestion] = pool.map { symbol in
            ZhuyinQuestion(
                symbols: [symbol],
                expectedKeys: [ZhuyinStandardMap.symbolToKey[symbol] ?? ""]
            )
        }

        if let seed = seed {
            var rng = SeededRandom(seed: seed)
            var result: [ZhuyinQuestion] = []
            var shuffled = allQuestions
            for _ in 0..<(count ?? pool.count) {
                let idx = Int.random(in: 0..<shuffled.count, using: &rng)
                result.append(shuffled.remove(at: idx))
                if shuffled.isEmpty { break }
            }
            return result
        } else {
            let limited = count.map { Array(pool.prefix($0)) } ?? pool
            return limited.map { symbol in
                ZhuyinQuestion(
                    symbols: [symbol],
                    expectedKeys: [ZhuyinStandardMap.symbolToKey[symbol] ?? ""]
                )
            }
        }
    }

    /// 產生音節練習題目（每個音節含 1~3 個符號）
    /// - Parameters:
    ///   - count: 題目數量
    ///   - seed: 隨機種子
    /// - Returns: 題目陣列
    static func generateSyllable(count: Int, seed: UInt64? = nil) -> [ZhuyinQuestion] {
        // 常見音節池（initial + final 常見組合 + medials）
        let combos: [(initials: [ZhuyinSymbol], finals: [ZhuyinSymbol])] = [
            // 聲母 + 韻母（無介音）
            ([ZhuyinSymbol("ㄅ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ"), ZhuyinSymbol("ㄜ")]),
            ([ZhuyinSymbol("ㄆ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄞ")]),
            ([ZhuyinSymbol("ㄇ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄣ")]),
            ([ZhuyinSymbol("ㄈ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄟ")]),
            ([ZhuyinSymbol("ㄉ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄢ")]),
            ([ZhuyinSymbol("ㄊ")], [ZhuyinSymbol("ㄠ"), ZhuyinSymbol("ㄤ")]),
            ([ZhuyinSymbol("ㄋ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄟ")]),
            ([ZhuyinSymbol("ㄌ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄠ")]),
            ([ZhuyinSymbol("ㄍ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ"), ZhuyinSymbol("ㄟ")]),
            ([ZhuyinSymbol("ㄎ")], [ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄤ")]),
            ([ZhuyinSymbol("ㄏ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄡ")]),
            ([ZhuyinSymbol("ㄐ")], [ZhuyinSymbol("ㄧ"), ZhuyinSymbol("ㄩ")]),
            ([ZhuyinSymbol("ㄑ")], [ZhuyinSymbol("ㄧ"), ZhuyinSymbol("ㄩ")]),
            ([ZhuyinSymbol("ㄒ")], [ZhuyinSymbol("ㄧ"), ZhuyinSymbol("ㄩ")]),
            ([ZhuyinSymbol("ㄓ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄧ")]),
            ([ZhuyinSymbol("ㄔ")], [ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄧ")]),
            ([ZhuyinSymbol("ㄕ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄧ")]),
            ([ZhuyinSymbol("ㄖ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄧ")]),
            ([ZhuyinSymbol("ㄗ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ"), ZhuyinSymbol("ㄧ")]),
            ([ZhuyinSymbol("ㄘ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ")]),
            ([ZhuyinSymbol("ㄙ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄜ")]),
            // 介音開頭
            ([ZhuyinSymbol("ㄧ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ"), ZhuyinSymbol("ㄠ")]),
            ([ZhuyinSymbol("ㄨ")], [ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ")]),
            ([ZhuyinSymbol("ㄩ")], [ZhuyinSymbol("ㄝ"), ZhuyinSymbol("ㄢ")])
        ]

        var questions: [ZhuyinQuestion] = []
        for combo in combos {
            for initial in combo.initials {
                for final_ in combo.finals {
                    let symbols = [initial, final_]
                    let keys = symbols.map { ZhuyinStandardMap.symbolToKey[$0] ?? "" }
                    questions.append(ZhuyinQuestion(symbols: symbols, expectedKeys: keys))
                }
            }
        }

        // 加入含介音的音節（initial + medial + final）
        let medials: [ZhuyinSymbol] = [ZhuyinSymbol("ㄧ"), ZhuyinSymbol("ㄨ"), ZhuyinSymbol("ㄩ")]
        let initialsWithMedial: [ZhuyinSymbol] = [
            ZhuyinSymbol("ㄅ"), ZhuyinSymbol("ㄆ"), ZhuyinSymbol("ㄇ"),
            ZhuyinSymbol("ㄈ"), ZhuyinSymbol("ㄉ"), ZhuyinSymbol("ㄊ"),
            ZhuyinSymbol("ㄍ"), ZhuyinSymbol("ㄎ"), ZhuyinSymbol("ㄏ"),
            ZhuyinSymbol("ㄐ"), ZhuyinSymbol("ㄑ"), ZhuyinSymbol("ㄒ"),
            ZhuyinSymbol("ㄓ"), ZhuyinSymbol("ㄔ"), ZhuyinSymbol("ㄕ"),
            ZhuyinSymbol("ㄖ"), ZhuyinSymbol("ㄗ"), ZhuyinSymbol("ㄘ"), ZhuyinSymbol("ㄙ")
        ]
        let finalsForMedial: [ZhuyinSymbol] = [
            ZhuyinSymbol("ㄚ"), ZhuyinSymbol("ㄛ"), ZhuyinSymbol("ㄜ"),
            ZhuyinSymbol("ㄝ"), ZhuyinSymbol("ㄞ"), ZhuyinSymbol("ㄟ"),
            ZhuyinSymbol("ㄠ"), ZhuyinSymbol("ㄡ"), ZhuyinSymbol("ㄢ"),
            ZhuyinSymbol("ㄣ"), ZhuyinSymbol("ㄤ"), ZhuyinSymbol("ㄥ")
        ]
        for medial in medials {
            for initial in initialsWithMedial {
                for final_ in finalsForMedial {
                    let symbols = [initial, medial, final_]
                    let keys = symbols.map { ZhuyinStandardMap.symbolToKey[$0] ?? "" }
                    questions.append(ZhuyinQuestion(symbols: symbols, expectedKeys: keys))
                }
            }
        }

        guard !questions.isEmpty else { return [] }

        if let seed = seed {
            var rng = SeededRandom(seed: seed)
            var shuffled = questions.shuffled(using: &rng)
            var result: [ZhuyinQuestion] = []
            for _ in 0..<min(count, questions.count) {
                result.append(shuffled.removeFirst())
            }
            return result
        } else {
            return Array(questions.prefix(count))
        }
    }

    /// 工廠方法：根據 mode 產生題目
    static func generate(
        mode: ZhuyinPracticeMode,
        order: ZhuyinQuestionOrder,
        count: Int? = nil,
        seed: UInt64? = nil
    ) -> [ZhuyinQuestion] {
        switch mode {
        case .singleSymbol:
            let totalCount = count ?? ZhuyinStandardMap.allSymbols.count
            if order == .random, let seed = seed {
                return generateSingleSymbol(count: totalCount, seed: seed)
            } else {
                return generateSingleSymbol(count: totalCount, seed: nil)
            }
        case .syllable:
            let totalCount = count ?? 30
            if order == .random, let seed = seed {
                return generateSyllable(count: totalCount, seed: seed)
            } else {
                return generateSyllable(count: totalCount, seed: nil)
            }
        }
    }
}
