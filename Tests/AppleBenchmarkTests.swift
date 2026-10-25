import Foundation
import Dispatch

public struct BenchmarkResult: CustomStringConvertible {
    public let name: String
    public let operations: Int
    public let elapsedNanoseconds: UInt64

    public var elapsedMilliseconds: Double {
        Double(elapsedNanoseconds) / 1_000_000.0
    }

    public var latencyNsPerOp: Double {
        Double(elapsedNanoseconds) / Double(operations)
    }

    public var throughputOpsPerSec: Double {
        let seconds = Double(elapsedNanoseconds) / 1_000_000_000.0
        guard seconds > 0 else { return 0 }
        return Double(operations) / seconds
    }

    public var description: String {
        let formattedThroughput = String(format: "%.0f", throughputOpsPerSec)
        let formattedLatency = String(format: "%.2f", latencyNsPerOp)
        let formattedMs = String(format: "%.2f", elapsedMilliseconds)
        return "| \(name.padding(toLength: 42, withPad: " ", startingAt: 0)) | \(String(operations).padding(toLength: 10, withPad: " ", startingAt: 0)) | \(formattedMs.padding(toLength: 10, withPad: " ", startingAt: 0)) ms | \(formattedLatency.padding(toLength: 12, withPad: " ", startingAt: 0)) ns/op | \(formattedThroughput.padding(toLength: 14, withPad: " ", startingAt: 0)) ops/s |"
    }
}

@main
struct AppleBenchmarkTests {
    static let vietnameseSampleTexts: [String] = [
        "ĐẠI SỐ & GIẢI TÍCH",
        "Giáo Dục Kinh Tế Và Pháp Luật",
        "Lịch Sử & Địa Lý",
        "Bài tập về nhà môn Tiếng Anh: Thì hiện tại hoàn thành và quá khứ đơn",
        "Kiểm tra 15 phút Vật Lý chương 2: Sóng cơ và sóng âm",
        "Thực hành Tin học: Lập trình Swift và thuật toán tìm kiếm nhị phân",
        "Hóa học 12: Phản ứng este hóa và xà phòng hóa chất béo",
        "Sinh học: Cơ chế phiên mã và dịch mã trong tế bào nhân thực",
        "Nhiệm vụ tuần 5: Hoàn thành đề cương ôn tập học kỳ 1 môn Toán",
        "Chuẩn bị bài thuyết trình Địa lí về biến đổi khí hậu toàn cầu",
        "Công nghệ thông tin: Cơ sở dữ liệu quan hệ và SQL nâng cao",
        "Ngữ văn: Phân tích đoạn trích trong tác phẩm Vợ chồng A Phủ",
        "Giáo dục Quốc phòng và An ninh: Điều lệnh đội ngũ từng người",
        "Toán ứng dụng: Ma trận nghịch đảo và hệ phương trình tuyến tính",
        "Tiếng Anh chuyên ngành: Technical writing and documentation",
        "Vẽ kỹ thuật & Hình họa giải tích không gian 3 chiều",
        "Tâm lý học đường và kỹ năng giao tiếp thuyết trình",
        "Hóa phân tích: Chuẩn độ axit bazơ và phương pháp đo điện thế",
        "Thực hành phòng thí nghiệm: Quan sát tiêu bản nhiễm sắc thể",
        "Ôn tập chuyên đề: Hình học không gian tọa độ Oxyz"
    ]

    static let searchSampleQueries: [String] = [
        "giai tich",
        "toan hoc 12",
        "kiem tra vat ly chuong 2",
        "bai tap hoa hoc este",
        "tieng anh thi hien tai hoan thanh",
        "lich su dia ly",
        "tin hoc swift",
        "sinh hoc phien ma",
        "kinh te phap luat 2026",
        "de cuong on tap",
        "doanh nghiep",
        "may tinh casio",
        "bai tap cuoi tuan",
        "on tap chuong 1 giai tich",
        "thuc hanh lab",
        "an ninh mang",
        "tieng anh chuyen nganh",
        "cong nghe thong tin",
        "hinh hoc oxyz",
        "nhiem vu tuan 5"
    ]

    static func benchmarkVietnameseNormalization(count: Int = 10_000) -> BenchmarkResult {
        var strings: [String] = []
        strings.reserveCapacity(count)
        let sampleCount = vietnameseSampleTexts.count
        for i in 0..<count {
            strings.append(vietnameseSampleTexts[i % sampleCount])
        }

        // Warmup
        for i in 0..<min(500, count) {
            _ = strings[i].normalizedForVietnameseSearch()
        }

        let start = DispatchTime.now().uptimeNanoseconds
        var totalLength = 0
        for i in 0..<count {
            let normalized = strings[i].normalizedForVietnameseSearch()
            totalLength += normalized.utf8.count
        }
        let end = DispatchTime.now().uptimeNanoseconds

        // Prevent dead-code elimination
        if totalLength == 0 { print("Warning: totalLength 0") }

        return BenchmarkResult(
            name: "Vietnamese Normalization",
            operations: count,
            elapsedNanoseconds: end - start
        )
    }

    static func benchmarkQueryTokenization(count: Int = 10_000) -> BenchmarkResult {
        var queries: [String] = []
        queries.reserveCapacity(count)
        let sampleCount = searchSampleQueries.count
        for i in 0..<count {
            queries.append(searchSampleQueries[i % sampleCount])
        }

        // Warmup
        for i in 0..<min(500, count) {
            _ = queries[i].searchQueryTokens()
        }

        let start = DispatchTime.now().uptimeNanoseconds
        var tokenCountSum = 0
        for i in 0..<count {
            let tokens = queries[i].searchQueryTokens()
            tokenCountSum += tokens.count
        }
        let end = DispatchTime.now().uptimeNanoseconds

        if tokenCountSum == 0 { print("Warning: tokenCountSum 0") }

        return BenchmarkResult(
            name: "Search Query Tokenization",
            operations: count,
            elapsedNanoseconds: end - start
        )
    }

    static func makeCourseworkDataset(count: Int) -> [Coursework] {
        var items: [Coursework] = []
        items.reserveCapacity(count)
        let courses = [
            "Đại số và Giải tích 12",
            "Vật lý đại cương",
            "Hóa hữu cơ",
            "Sinh học phân tử",
            "Lịch sử Việt Nam",
            "Địa lý kinh tế",
            "Ngữ văn 12",
            "Tiếng Anh nâng cao",
            "Giáo dục kinh tế và pháp luật",
            "Tin học lập trình Swift"
        ]

        let cal = Calendar.current
        let now = Date()

        for i in 0..<count {
            let course = courses[i % courses.count]
            let title: String
            let desc: String?
            let dueDate: Date?
            let status: SubmissionStatus
            let isManual: Bool

            switch i % 5 {
            case 0:
                title = "Giải tích chương \(i)"
                desc = "Ôn tập kiến thức giải tích và làm bài tập SGK trang \(i)"
                dueDate = cal.date(byAdding: .hour, value: 2, to: now)
                status = .pending
                isManual = false
            case 1:
                title = "Bài tập con lắc đơn vật lý \(i)"
                desc = "Lập báo cáo thí nghiệm thực hành con lắc"
                dueDate = cal.date(byAdding: .day, value: 1, to: now)
                status = .pending
                isManual = false
            case 2:
                title = "Phản ứng este hóa \(i)"
                desc = "Hoàn thành phương trình phản ứng hóa học"
                dueDate = cal.date(byAdding: .day, value: -1, to: now)
                status = .turnedIn
                isManual = true
            case 3:
                title = "Tiếng Anh chuyên ngành bài đọc số \(i)"
                desc = "Dịch đoạn văn và trả lời 10 câu hỏi trắc nghiệm"
                dueDate = cal.date(byAdding: .day, value: 3, to: now)
                status = .returned
                isManual = false
            default:
                title = "Ôn thi học kỳ môn \(course) đợt \(i)"
                desc = nil
                dueDate = nil
                status = .pending
                isManual = false
            }

            let item = Coursework(
                id: "cw_\(i)",
                courseId: "c_\(i % 10)",
                courseName: course,
                title: title,
                description: desc,
                dueDate: dueDate,
                status: status,
                isManuallyCompleted: isManual
            )
            items.append(item)
        }
        return items
    }

    static func benchmarkSearchScoring(items: [Coursework], label: String) -> BenchmarkResult {
        let tokens = ["giai", "tich"]
        let rawQuery = "giai tich"

        // Warmup
        for i in 0..<min(200, items.count) {
            _ = items[i].searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
        }

        let start = DispatchTime.now().uptimeNanoseconds
        var totalScore = 0
        for i in 0..<items.count {
            totalScore += items[i].searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
        }
        let end = DispatchTime.now().uptimeNanoseconds

        if totalScore == 0 { print("Warning: totalScore 0") }

        return BenchmarkResult(
            name: "Search Scoring (\(label))",
            operations: items.count,
            elapsedNanoseconds: end - start
        )
    }

    static func benchmarkDateBoundaryAndStatus(items: [Coursework]) -> BenchmarkResult {
        let count = items.count

        // Warmup
        for i in 0..<min(500, count) {
            let item = items[i]
            _ = item.isCompleted
            _ = item.isDueToday
            _ = item.isDueTomorrow
            _ = item.compactDueString
        }

        let start = DispatchTime.now().uptimeNanoseconds
        var checkSum = 0
        for i in 0..<count {
            let item = items[i]
            if item.isCompleted { checkSum += 1 }
            if item.isDueToday { checkSum += 2 }
            if item.isDueTomorrow { checkSum += 4 }
            if item.isPast { checkSum += 8 }
            checkSum += item.compactDueString.utf8.count
        }
        let end = DispatchTime.now().uptimeNanoseconds

        if checkSum == 0 { print("Warning: checkSum 0") }

        return BenchmarkResult(
            name: "Date Boundary & Status Check",
            operations: count,
            elapsedNanoseconds: end - start
        )
    }

    static func benchmarkSubjectClassification(items: [Coursework]) -> BenchmarkResult {
        let count = items.count

        // Warmup
        for i in 0..<min(500, count) {
            _ = SubjectArtHelper.category(for: items[i].courseName, title: items[i].title)
            _ = SubjectArtHelper.badgeCode(for: items[i].courseName, title: items[i].title)
        }

        let start = DispatchTime.now().uptimeNanoseconds
        var codeLengthSum = 0
        for i in 0..<count {
            let item = items[i]
            let cat = SubjectArtHelper.category(for: item.courseName, title: item.title)
            let badge = SubjectArtHelper.badgeCode(for: cat, courseName: item.courseName, title: item.title)
            codeLengthSum += badge.utf8.count
        }
        let end = DispatchTime.now().uptimeNanoseconds

        if codeLengthSum == 0 { print("Warning: codeLengthSum 0") }

        return BenchmarkResult(
            name: "Subject Classification & Badges",
            operations: count,
            elapsedNanoseconds: end - start
        )
    }

    static func main() {
        print("==========================================================================================================")
        print("                        APPLE / SWIFT CORE ALGORITHMIC PERFORMANCE BENCHMARK                              ")
        print("==========================================================================================================")

        print("\n[1/5] Preparing datasets...")
        let items1k = makeCourseworkDataset(count: 1_000)
        let items10k = makeCourseworkDataset(count: 10_000)

        print("[2/5] Running benchmarks...")
        var results: [BenchmarkResult] = []

        print(" -> Benchmarking Vietnamese Diacritics Normalization (10,000 strings)...")
        results.append(benchmarkVietnameseNormalization(count: 10_000))

        print(" -> Benchmarking Search Query Tokenization (10,000 queries)...")
        results.append(benchmarkQueryTokenization(count: 10_000))

        print(" -> Benchmarking Search Relevance Scoring (1,000 items)...")
        results.append(benchmarkSearchScoring(items: items1k, label: "1,000 items"))

        print(" -> Benchmarking Search Relevance Scoring (10,000 items)...")
        results.append(benchmarkSearchScoring(items: items10k, label: "10,000 items"))

        print(" -> Benchmarking Date Boundary & Status Checking (10,000 items)...")
        results.append(benchmarkDateBoundaryAndStatus(items: items10k))

        print(" -> Benchmarking Subject Classification & Badge Code Extraction (10,000 items)...")
        results.append(benchmarkSubjectClassification(items: items10k))

        print("\n==========================================================================================================")
        print("| Benchmark                                  | Operations | Time (ms)    | Latency      | Throughput     |")
        print("|--------------------------------------------|------------|--------------|--------------|----------------|")
        for res in results {
            print(res.description)
        }
        print("==========================================================================================================")
    }
}
