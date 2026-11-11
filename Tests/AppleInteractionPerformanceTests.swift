import Foundation
import Dispatch

@main
struct AppleInteractionPerformanceTests {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError(message) }
    }

    static func legacyMatches(_ index: String, tokens: [String]) -> Bool {
        tokens.allSatisfy { token in
            if index.contains(token) { return true }
            let alternative = cleanTelexKeystrokes(token)
            return alternative != token && index.contains(alternative)
        }
    }

    static func main() {
        let samples = [
            "Đại số & Giải tích", "Bài tập về nhà Vật lý chương 2", "Kiểm tra 15 phút",
            "Ôn thi học kỳ môn Toán", "Lập trình Swift", "中文 日本語", "👩‍💻 học bài",
            "cafe\u{301}", "a\u{FE0F}", "SGK trang 20", "", "toan\0hoc"
        ]
        let queries = ["giai tich", "toans", "ddai", "btvn", "15p", "khong co", "", " \n ",
                       "中文", "👩‍💻", "café", "a", "toan/hoc", "toan\0hoc"]
        for text in samples {
            let index = Coursework.buildSearchIndex(title: text, courseName: "Toán", description: text)
            for raw in queries {
                let query = CourseworkSearchQuery(raw)
                require(query.matches(index) == legacyMatches(index, tokens: query.tokens),
                        "Search behavior changed for \(raw) in \(text)")
            }
        }

        struct Context: Equatable {
            let version: Int
            var query: String = ""
            var subject: String = "Tất cả"
        }
        let cache = CategoryResultCache<String, Context, [String]>()
        var computes = 0
        func get(_ category: String, _ context: Context, _ result: [String]) -> [String] {
            cache.value(for: category, context: context) {
                computes += 1
                return result
            }
        }
        for _ in 0..<20 {
            require(get("tomorrow", Context(version: 1), ["a"]) == ["a"], "Wrong tomorrow cache")
            require(get("upcoming", Context(version: 1), ["a", "b"]) == ["a", "b"], "Wrong upcoming cache")
            require(get("completed", Context(version: 1), []) == [], "Empty result should be cached")
        }
        require(computes == 3, "Switching categories must not evict another category")
        require(get("tomorrow", Context(version: 2), ["b"]) == ["b"], "Same-count edits must invalidate")
        require(get("tomorrow", Context(version: 2, query: "b"), []) == [], "Query must invalidate")
        require(get("tomorrow", Context(version: 2, query: "b", subject: "Lý"), ["c"]) == ["c"],
                "Subject filter must invalidate")
        require(computes == 6, "Unexpected cache computation count")
        print("PASS: search parity (including Unicode/Telex), tab reuse, same-count edits and filter invalidation")

        let indices = (0..<10_000).map { i in
            Coursework.buildSearchIndex(title: samples[i % 5], courseName: "Đại số và Giải tích 12",
                                        description: "Ôn tập kiến thức và làm bài tập SGK trang \(i)")
        }
        let prepared = ["giai tich", "toans", "vat ly", "sgk", "khong co ket qua"].map(CourseworkSearchQuery.init)
        func measure(_ match: (String, CourseworkSearchQuery) -> Bool) -> (UInt64, Int) {
            var checksum = 0
            let start = DispatchTime.now().uptimeNanoseconds
            for _ in 0..<10 {
                for query in prepared {
                    for index in indices where match(index, query) { checksum += 1 }
                }
            }
            return (DispatchTime.now().uptimeNanoseconds - start, checksum)
        }
        var legacyTimes: [UInt64] = []
        var preparedTimes: [UInt64] = []
        for _ in 0..<5 {
            let legacy = measure { legacyMatches($0, tokens: $1.tokens) }
            let optimized = measure { $1.matches($0) }
            require(legacy.1 == optimized.1, "Benchmark results must agree")
            legacyTimes.append(legacy.0)
            preparedTimes.append(optimized.0)
        }
        let legacy = Double(legacyTimes.sorted()[2]) / 1_000_000
        let optimized = Double(preparedTimes.sorted()[2]) / 1_000_000
        print(String(format: "Search matching, 10,000 items × 5 queries × 10 rounds (median of 5): %.2f ms → %.2f ms (%.2fx)",
                     legacy, optimized, legacy / optimized))
    }
}
