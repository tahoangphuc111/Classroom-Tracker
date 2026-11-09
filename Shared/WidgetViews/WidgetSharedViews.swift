import SwiftUI
import WidgetKit
import os

public enum SubjectCategory: Sendable {
    case computerScience
    case math
    case english
    case literature
    case physics
    case chemistry
    case biology
    case history
    case defenseEducation
    case localEducation
    case experientialActivities
    case other
}

public struct SubjectArtHelper {
    public struct VisualTheme: Sendable {
        public let category: SubjectCategory
        public let icon: String
        public let themeColor: Color
        public let bannerBackground: Color
    }

    private struct CompoundCategoryKey: Hashable {
        let courseName: String
        let title: String
    }

    private static let cacheLock = NSLock()
    private static var courseCategoryCache: [String: SubjectCategory] = [:]
    private static var categoryCache: [CompoundCategoryKey: SubjectCategory] = [:]
    private static var courseBadgeCache: [String: String] = [:]

    private static let standardThemes: [SubjectCategory: VisualTheme] = [
        .computerScience: VisualTheme(category: .computerScience, icon: "desktopcomputer", themeColor: Color(red: 0.08, green: 0.68, blue: 0.54), bannerBackground: Color(red: 0.06, green: 0.58, blue: 0.50)),
        .math: VisualTheme(category: .math, icon: "function", themeColor: Color(red: 0.95, green: 0.60, blue: 0.10), bannerBackground: Color(red: 0.88, green: 0.50, blue: 0.08)),
        .english: VisualTheme(category: .english, icon: "character.book.closed", themeColor: Color(red: 0.15, green: 0.58, blue: 0.92), bannerBackground: Color(red: 0.12, green: 0.48, blue: 0.88)),
        .literature: VisualTheme(category: .literature, icon: "text.book.closed", themeColor: Color(red: 0.92, green: 0.38, blue: 0.22), bannerBackground: Color(red: 0.86, green: 0.34, blue: 0.20)),
        .physics: VisualTheme(category: .physics, icon: "atom", themeColor: Color(red: 0.45, green: 0.38, blue: 0.88), bannerBackground: Color(red: 0.40, green: 0.34, blue: 0.84)),
        .chemistry: VisualTheme(category: .chemistry, icon: "flask", themeColor: Color(red: 0.86, green: 0.28, blue: 0.68), bannerBackground: Color(red: 0.80, green: 0.24, blue: 0.60)),
        .biology: VisualTheme(category: .biology, icon: "leaf", themeColor: Color(red: 0.20, green: 0.72, blue: 0.40), bannerBackground: Color(red: 0.14, green: 0.60, blue: 0.34)),
        .history: VisualTheme(category: .history, icon: "clock.arrow.circlepath", themeColor: Color(red: 0.85, green: 0.52, blue: 0.16), bannerBackground: Color(red: 0.80, green: 0.46, blue: 0.14)),
        .defenseEducation: VisualTheme(category: .defenseEducation, icon: "shield", themeColor: Color(red: 0.16, green: 0.58, blue: 0.28), bannerBackground: Color(red: 0.12, green: 0.50, blue: 0.22)),
        .localEducation: VisualTheme(category: .localEducation, icon: "map", themeColor: Color(red: 0.05, green: 0.58, blue: 0.53), bannerBackground: Color(red: 0.04, green: 0.50, blue: 0.46)),
        .experientialActivities: VisualTheme(category: .experientialActivities, icon: "sparkles", themeColor: Color(red: 0.95, green: 0.42, blue: 0.12), bannerBackground: Color(red: 0.88, green: 0.36, blue: 0.10)),
        .other: VisualTheme(category: .other, icon: "book.closed", themeColor: Color(red: 0.40, green: 0.52, blue: 0.64), bannerBackground: Color(red: 0.30, green: 0.44, blue: 0.60))
    ]

    private static let maxCacheSize = 16384

    public static func clearCaches() {
        cacheLock.lock()
        courseCategoryCache.removeAll(keepingCapacity: false)
        categoryCache.removeAll(keepingCapacity: false)
        courseBadgeCache.removeAll(keepingCapacity: false)
        cacheLock.unlock()
    }

    public static func category(for courseName: String, title: String? = nil) -> SubjectCategory {
        let hasTitle = !(title?.isEmpty ?? true)
        if !hasTitle {
            cacheLock.lock()
            if let cached = courseCategoryCache[courseName] {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()

            let computed = computeCategory(for: courseName, title: nil)
            cacheLock.lock()
            if courseCategoryCache.count >= maxCacheSize {
                courseCategoryCache.removeAll()
            }
            courseCategoryCache[courseName] = computed
            cacheLock.unlock()
            return computed
        }

        let key = CompoundCategoryKey(courseName: courseName, title: title ?? "")
        cacheLock.lock()
        if let cached = categoryCache[key] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let computed = computeCategory(for: courseName, title: title)
        cacheLock.lock()
        if categoryCache.count >= maxCacheSize {
            categoryCache.removeAll()
        }
        categoryCache[key] = computed
        cacheLock.unlock()

        return computed
    }

    public static func theme(for category: SubjectCategory) -> VisualTheme {
        standardThemes[category] ?? VisualTheme(
            category: category,
            icon: icon(for: category),
            themeColor: themeColor(for: category),
            bannerBackground: bannerBackground(for: category)
        )
    }

    public static func theme(for courseName: String, title: String? = nil) -> VisualTheme {
        let cat = category(for: courseName, title: title)
        return theme(for: cat)
    }

    public static func badgeCode(for category: SubjectCategory, courseName: String = "", title: String? = nil) -> String {
        switch category {
        case .computerScience: return "TIN"
        case .math: return "TOÁN"
        case .english: return "ANH"
        case .literature: return "VĂN"
        case .physics: return "LÝ"
        case .chemistry: return "HOÁ"
        case .biology: return "SINH"
        case .history: return "SỬ"
        case .defenseEducation: return "GDQP"
        case .localEducation: return "GDĐP"
        case .experientialActivities: return "HĐTN"
        case .other:
            let cleaned = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 3 {
                if !courseName.isEmpty {
                    cacheLock.lock()
                    if let cached = courseBadgeCache[courseName] {
                        cacheLock.unlock()
                        return cached
                    }
                    cacheLock.unlock()
                }
                let badge = String(cleaned.prefix(3)).uppercased()
                if !courseName.isEmpty {
                    cacheLock.lock()
                    if courseBadgeCache.count >= maxCacheSize { courseBadgeCache.removeAll() }
                    courseBadgeCache[courseName] = badge
                    cacheLock.unlock()
                }
                return badge
            }
            let titleCleaned = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if titleCleaned.count >= 3 {
                return String(titleCleaned.prefix(3)).uppercased()
            }
            if !cleaned.isEmpty {
                return cleaned.uppercased()
            }
            if !titleCleaned.isEmpty {
                return titleCleaned.uppercased()
            }
            return "MÔN"
        }
    }

    public static func badgeCode(for courseName: String, title: String? = nil) -> String {
        let cat = category(for: courseName, title: title)
        return badgeCode(for: cat, courseName: courseName, title: title)
    }

    private struct TokenFlags: OptionSet {
        let rawValue: UInt64

        static let math = TokenFlags(rawValue: 1 << 0)
        static let physics = TokenFlags(rawValue: 1 << 1)
        static let chemistry = TokenFlags(rawValue: 1 << 2)
        static let biology = TokenFlags(rawValue: 1 << 3)
        static let history = TokenFlags(rawValue: 1 << 4)
        static let literature = TokenFlags(rawValue: 1 << 5)
        static let english = TokenFlags(rawValue: 1 << 6)
        static let cs = TokenFlags(rawValue: 1 << 7)
        static let defense = TokenFlags(rawValue: 1 << 8)
        static let local = TokenFlags(rawValue: 1 << 9)
        static let experiential = TokenFlags(rawValue: 1 << 10)

        static let ly = TokenFlags(rawValue: 1 << 11)
        static let hoa = TokenFlags(rawValue: 1 << 12)
        static let sinh = TokenFlags(rawValue: 1 << 13)
        static let su = TokenFlags(rawValue: 1 << 14)
        static let van = TokenFlags(rawValue: 1 << 15)
        static let anh = TokenFlags(rawValue: 1 << 16)
        static let tin = TokenFlags(rawValue: 1 << 17)
        static let tu = TokenFlags(rawValue: 1 << 18)

        // Anchor tokens to gate substring scans
        static let wGiai = TokenFlags(rawValue: 1 << 19)
        static let wDai = TokenFlags(rawValue: 1 << 20)
        static let wHinh = TokenFlags(rawValue: 1 << 21)
        static let wXac = TokenFlags(rawValue: 1 << 22)
        static let wLuong = TokenFlags(rawValue: 1 << 23)
        static let wDao = TokenFlags(rawValue: 1 << 24)
        static let wTich = TokenFlags(rawValue: 1 << 25)
        static let wThong = TokenFlags(rawValue: 1 << 26)
        static let wVi = TokenFlags(rawValue: 1 << 27)
        static let wMa = TokenFlags(rawValue: 1 << 28)

        static let wVat = TokenFlags(rawValue: 1 << 29)
        static let wCo = TokenFlags(rawValue: 1 << 30)
        static let wNhiet = TokenFlags(rawValue: 1 << 31)
        static let wQuang = TokenFlags(rawValue: 1 << 32)
        static let wDien = TokenFlags(rawValue: 1 << 33)
        static let wSong = TokenFlags(rawValue: 1 << 34)

        static let wY = TokenFlags(rawValue: 1 << 35)
        static let wDi = TokenFlags(rawValue: 1 << 36)
        static let wTe = TokenFlags(rawValue: 1 << 37)
        static let wTieu = TokenFlags(rawValue: 1 << 38)

        static let wLap = TokenFlags(rawValue: 1 << 39)
        static let wThuat = TokenFlags(rawValue: 1 << 40)
        static let wCong = TokenFlags(rawValue: 1 << 41)
        static let wKhoa = TokenFlags(rawValue: 1 << 42)
        static let wCau = TokenFlags(rawValue: 1 << 43)
        static let wTri = TokenFlags(rawValue: 1 << 44)
        static let wMachine = TokenFlags(rawValue: 1 << 45)
        static let wHe = TokenFlags(rawValue: 1 << 46)
        static let wKien = TokenFlags(rawValue: 1 << 47)

        static let wQuoc = TokenFlags(rawValue: 1 << 48)
        static let wQuan = TokenFlags(rawValue: 1 << 49)
        static let wGiao = TokenFlags(rawValue: 1 << 50)
        static let wHoat = TokenFlags(rawValue: 1 << 51)
        static let wHuong = TokenFlags(rawValue: 1 << 52)
    }

    private final class FastTokenTrie {
        final class Node {
            var flag: TokenFlags = []
            var children: [Node?] = Array(repeating: nil, count: 26)
        }

        let root = Node()

        init() {
            func insert(_ word: String, _ flag: TokenFlags) {
                var curr = root
                for b in word.utf8 {
                    let idx = Int(b - 97)
                    if idx >= 0 && idx < 26 {
                        if curr.children[idx] == nil {
                            curr.children[idx] = Node()
                        }
                        curr = curr.children[idx]!
                    }
                }
                curr.flag.insert(flag)
            }

            insert("toan", .math)
            insert("math", .math)
            insert("maths", .math)
            insert("calculus", .math)
            insert("algebra", .math)
            insert("geometry", .math)
            insert("trigonometry", .math)
            insert("statistics", .math)
            insert("discrete", .math)

            insert("giai", .wGiai)
            insert("dai", .wDai)
            insert("hinh", .wHinh)
            insert("xac", .wXac)
            insert("luong", .wLuong)
            insert("dao", .wDao)
            insert("tich", .wTich)
            insert("thong", .wThong)
            insert("vi", .wVi)
            insert("ma", .wMa)

            insert("physics", .physics)
            insert("mechanics", .physics)
            insert("thermodynamics", .physics)
            insert("optics", .physics)
            insert("ly", .ly)
            insert("li", .ly)
            insert("vat", .wVat)
            insert("co", .wCo)
            insert("nhiet", .wNhiet)
            insert("quang", .wQuang)
            insert("dien", .wDien)
            insert("song", .wSong)

            insert("chemistry", .chemistry)
            insert("chem", .chemistry)
            insert("biochemistry", .chemistry)
            insert("hoa", .hoa)

            insert("biology", .biology)
            insert("bio", .biology)
            insert("genetics", .biology)
            insert("ecology", .biology)
            insert("sinh", .sinh)
            insert("y", .wY)
            insert("di", .wDi)
            insert("te", .wTe)
            insert("tieu", .wTieu)

            insert("history", .history)
            insert("su", .su)

            insert("literature", .literature)
            insert("writing", .literature)
            insert("essay", .literature)
            insert("van", .van)

            insert("english", .english)
            insert("ielts", .english)
            insert("toeic", .english)
            insert("toefl", .english)
            insert("anh", .anh)

            insert("gdqp", .defense)
            insert("gddp", .local)
            insert("hdtn", .experiential)

            insert("android", .cs)
            insert("ios", .cs)
            insert("swift", .cs)
            insert("python", .cs)
            insert("java", .cs)
            insert("cntt", .cs)
            insert("it", .cs)
            insert("ctdl", .cs)
            insert("cpp", .cs)
            insert("kotlin", .cs)
            insert("javascript", .cs)
            insert("typescript", .cs)
            insert("tin", .tin)
            insert("tu", .tu)
            insert("lap", .wLap)
            insert("thuat", .wThuat)
            insert("cong", .wCong)
            insert("khoa", .wKhoa)
            insert("cau", .wCau)
            insert("tri", .wTri)
            insert("machine", .wMachine)
            insert("he", .wHe)
            insert("kien", .wKien)

            insert("quoc", .wQuoc)
            insert("quan", .wQuan)
            insert("giao", .wGiao)
            insert("hoat", .wHoat)
            insert("huong", .wHuong)
        }

        @inline(__always)
        func lookup(ptr: UnsafePointer<UInt8>, count: Int) -> TokenFlags {
            var curr = root
            for i in 0..<count {
                let b = ptr[i]
                guard b >= 97 && b <= 122 else { return [] }
                let idx = Int(b - 97)
                guard let next = curr.children[idx] else { return [] }
                curr = next
            }
            return curr.flag
        }

        @inline(__always)
        func scan(buf: FastSearchBuffer) -> TokenFlags {
            var flags: TokenFlags = []
            var start = -1
            let count = buf.count
            let ptr = buf.ptr
            for i in 0..<count {
                let b = ptr[i]
                let isWordChar = (b >= 97 && b <= 122) || (b >= 48 && b <= 57)
                if isWordChar {
                    if start == -1 { start = i }
                } else if start != -1 {
                    let tokenLen = i - start
                    if tokenLen >= 1 && tokenLen <= 20 {
                        flags.insert(lookup(ptr: ptr + start, count: tokenLen))
                    }
                    start = -1
                }
            }
            if start != -1 {
                let tokenLen = count - start
                if tokenLen >= 1 && tokenLen <= 20 {
                    flags.insert(lookup(ptr: ptr + start, count: tokenLen))
                }
            }
            return flags
        }
    }

    private struct StaticPattern {
        let bytes: [UInt8]
        let count: Int

        init(_ str: String) {
            self.bytes = Array(str.utf8)
            self.count = self.bytes.count
        }

        @inline(__always)
        func isFound(in buf: FastSearchBuffer) -> Bool {
            guard count <= buf.count else { return false }
            return bytes.withUnsafeBufferPointer { b in
                guard let base = b.baseAddress else { return false }
                if count == 1 {
                    return memchr(buf.ptr, Int32(base.pointee), buf.count) != nil
                }
                return memmem(buf.ptr, buf.count, base, count) != nil
            }
        }
    }

    private static let tokenTrie = FastTokenTrie()

    private static let p_giai_tich = StaticPattern("giai tich")
    private static let p_dai_so = StaticPattern("dai so")
    private static let p_hinh_hoc = StaticPattern("hinh hoc")
    private static let p_xac_suat = StaticPattern("xac suat")
    private static let p_luong_giac = StaticPattern("luong giac")
    private static let p_dao_ham = StaticPattern("dao ham")
    private static let p_tich_phan = StaticPattern("tich phan")
    private static let p_toan_cao_cap = StaticPattern("toan cao cap")
    private static let p_toan_roi_rac = StaticPattern("toan roi rac")
    private static let p_thong_ke = StaticPattern("thong ke")
    private static let p_vi_phan = StaticPattern("vi phan")
    private static let p_ma_tran = StaticPattern("ma tran")
    private static let p_dien_toan = StaticPattern("dien toan")
    private static let p_an_toan = StaticPattern("an toan")
    private static let p_thanh_toan = StaticPattern("thanh toan")
    private static let p_hoan_toan = StaticPattern("hoan toan")

    private static let p_vat_ly = StaticPattern("vat ly")
    private static let p_vat_li = StaticPattern("vat li")
    private static let p_mon_ly = StaticPattern("mon ly")
    private static let p_mon_li = StaticPattern("mon li")
    private static let p_sbt_ly = StaticPattern("sbt ly")
    private static let p_sbt_li = StaticPattern("sbt li")
    private static let p_co_hoc = StaticPattern("co hoc")
    private static let p_nhiet_hoc = StaticPattern("nhiet hoc")
    private static let p_quang_hoc = StaticPattern("quang hoc")
    private static let p_dien_tu = StaticPattern("dien tu")
    private static let p_vat_ly_dai_cuong = StaticPattern("vat ly dai cuong")
    private static let p_vat_li_dai_cuong = StaticPattern("vat li dai cuong")
    private static let p_dao_dong = StaticPattern("dao dong")
    private static let p_song_co = StaticPattern("song co")
    private static let p_quan_ly = StaticPattern("quan ly")
    private static let p_quan_li = StaticPattern("quan li")
    private static let p_xu_ly = StaticPattern("xu ly")
    private static let p_xu_li = StaticPattern("xu li")
    private static let p_tam_ly = StaticPattern("tam ly")
    private static let p_tam_li = StaticPattern("tam li")
    private static let p_phap_ly = StaticPattern("phap ly")
    private static let p_phap_li = StaticPattern("phap li")
    private static let p_dia_ly = StaticPattern("dia ly")
    private static let p_dia_li = StaticPattern("dia li")
    private static let p_triet_ly = StaticPattern("triet ly")
    private static let p_triet_li = StaticPattern("triet li")
    private static let p_ly_thuyet = StaticPattern("ly thuyet")
    private static let p_li_thuyet = StaticPattern("li thuyet")
    private static let p_ly_luan = StaticPattern("ly luan")
    private static let p_li_luan = StaticPattern("li luan")
    private static let p_ly_do = StaticPattern("ly do")
    private static let p_li_do = StaticPattern("li do")
    private static let p_hop_ly = StaticPattern("hop ly")
    private static let p_hop_li = StaticPattern("hop li")
    private static let p_dai_ly = StaticPattern("dai ly")
    private static let p_dai_li = StaticPattern("dai li")

    private static let p_hoa_hoc = StaticPattern("hoa hoc")
    private static let p_mon_hoa = StaticPattern("mon hoa")
    private static let p_hoa_huu_co = StaticPattern("hoa huu co")
    private static let p_hoa_vo_co = StaticPattern("hoa vo co")
    private static let p_hoa_dai_cuong = StaticPattern("hoa dai cuong")
    private static let p_hoa_phan_tich = StaticPattern("hoa phan tich")
    private static let p_tu_dong_hoa = StaticPattern("tu dong hoa")
    private static let p_tien_hoa = StaticPattern("tien hoa")
    private static let p_tieu_hoa = StaticPattern("tieu hoa")
    private static let p_hoa_don = StaticPattern("hoa don")
    private static let p_van_hoa = StaticPattern("van hoa")
    private static let p_toi_uu_hoa = StaticPattern("toi uu hoa")
    private static let p_chuan_hoa = StaticPattern("chuan hoa")
    private static let p_cong_nghiep_hoa = StaticPattern("cong nghiep hoa")
    private static let p_hien_dai_hoa = StaticPattern("hien dai hoa")
    private static let p_ao_hoa = StaticPattern("ao hoa")
    private static let p_so_hoa = StaticPattern("so hoa")
    private static let p_hoa_binh = StaticPattern("hoa binh")
    private static let p_hoa_hop = StaticPattern("hoa hop")
    private static let p_hoa_than = StaticPattern("hoa than")

    private static let p_sinh_hoc = StaticPattern("sinh hoc")
    private static let p_mon_sinh = StaticPattern("mon sinh")
    private static let p_y_hoc = StaticPattern("y hoc")
    private static let p_di_truyen = StaticPattern("di truyen")
    private static let p_te_bao = StaticPattern("te bao")
    private static let p_vi_sinh = StaticPattern("vi sinh")
    private static let p_sinh_thai = StaticPattern("sinh thai")
    private static let p_hoc_sinh = StaticPattern("hoc sinh")
    private static let p_sinh_vien = StaticPattern("sinh vien")
    private static let p_sinh_hoat = StaticPattern("sinh hoat")

    private static let p_lich_su = StaticPattern("lich su")
    private static let p_lich_su_trong = StaticPattern("lich su trong")
    private static let p_giao_tiep = StaticPattern("giao tiep")
    private static let p_ung_xu = StaticPattern("ung xu")
    private static let p_mon_su = StaticPattern("mon su")
    private static let p_su_dung = StaticPattern("su dung")

    private static let p_ngu_van = StaticPattern("ngu van")
    private static let p_tieng_viet = StaticPattern("tieng viet")
    private static let p_mon_van = StaticPattern("mon van")
    private static let p_van_phong = StaticPattern("van phong")
    private static let p_van_minh = StaticPattern("van minh")
    private static let p_van_ban = StaticPattern("van ban")
    private static let p_luan_van = StaticPattern("luan van")

    private static let p_tieng_anh = StaticPattern("tieng anh")
    private static let p_mon_anh = StaticPattern("mon anh")
    private static let p_hinh_anh = StaticPattern("hinh anh")
    private static let p_am_thanh = StaticPattern("am thanh")
    private static let p_thay = StaticPattern("thay")
    private static let p_co = StaticPattern("co ")
    private static let p_gv = StaticPattern("gv")

    private static let p_tin_hoc = StaticPattern("tin hoc")
    private static let p_mon_tin = StaticPattern("mon tin")
    private static let p_lap_trinh = StaticPattern("lap trinh")
    private static let p_di_dong = StaticPattern("di dong")
    private static let p_cong_nghe_thong_tin = StaticPattern("cong nghe thong tin")
    private static let p_thuat_toan = StaticPattern("thuat toan")
    private static let p_co_so_du_lieu = StaticPattern("co so du lieu")
    private static let p_khoa_hoc_may_tinh = StaticPattern("khoa hoc may tinh")
    private static let p_cau_truc_du_lieu = StaticPattern("cau truc du lieu")
    private static let p_tri_tue_nhan_tao = StaticPattern("tri tue nhan tao")
    private static let p_machine_learning = StaticPattern("machine learning")
    private static let p_he_dieu_hanh = StaticPattern("he dieu hanh")
    private static let p_kien_truc_may_tinh = StaticPattern("kien truc may tinh")
    private static let p_thong_tin = StaticPattern("thong tin")
    private static let p_ban_tin = StaticPattern("ban tin")
    private static let p_tin_tuc = StaticPattern("tin tuc")
    private static let p_niem_tin = StaticPattern("niem tin")

    private static let p_giao_duc_quoc_phong = StaticPattern("giao duc quoc phong")
    private static let p_quoc_phong_an_ninh = StaticPattern("quoc phong an ninh")
    private static let p_an_ninh_quoc_phong = StaticPattern("an ninh quoc phong")
    private static let p_quan_su = StaticPattern("quan su")
    private static let p_giao_duc_qp = StaticPattern("giao duc qp")

    private static let p_giao_duc_dia_phuong = StaticPattern("giao duc dia phuong")
    private static let p_giao_duc_dp = StaticPattern("giao duc dp")

    private static let p_hoat_dong_trai_nghiem = StaticPattern("hoat dong trai nghiem")
    private static let p_huong_nghiep = StaticPattern("huong nghiep")
    private static let p_sinh_hoat_duoi_co = StaticPattern("sinh hoat duoi co")
    private static let p_sinh_hoat_lop = StaticPattern("sinh hoat lop")

    private static func classifyCandidate(rawText: String) -> SubjectCategory? {
        if rawText.isEmpty { return nil }
        let norm = rawText.normalizedForVietnameseSearch()
        if norm.isEmpty { return nil }

        return norm.utf8.withContiguousStorageIfAvailable { buf -> SubjectCategory? in
            guard let base = buf.baseAddress, buf.count > 0 else { return nil }
            let sBuf = FastSearchBuffer(ptr: base, count: buf.count)
            let flags = tokenTrie.scan(buf: sBuf)

            // Math
            var hasMath = flags.contains(.math)
            if !hasMath {
                if flags.contains(.wGiai) && p_giai_tich.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wDai) && p_dai_so.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wHinh) && p_hinh_hoc.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wXac) && p_xac_suat.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wLuong) && p_luong_giac.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wDao) && p_dao_ham.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wTich) && p_tich_phan.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wThong) && p_thong_ke.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wVi) && p_vi_phan.isFound(in: sBuf) { hasMath = true }
                else if flags.contains(.wMa) && p_ma_tran.isFound(in: sBuf) { hasMath = true }
            } else {
                if p_toan_cao_cap.isFound(in: sBuf) || p_toan_roi_rac.isFound(in: sBuf) { hasMath = true }
            }

            if hasMath {
                if flags.contains(.math) {
                    if !p_dien_toan.isFound(in: sBuf) &&
                        !p_an_toan.isFound(in: sBuf) &&
                        !p_thanh_toan.isFound(in: sBuf) &&
                        !p_hoan_toan.isFound(in: sBuf) {
                        return .math
                    }
                } else {
                    return .math
                }
            }

            // Physics
            var hasPhysics = flags.contains(.physics)
            if !hasPhysics {
                if flags.contains(.wVat) {
                    if p_vat_ly.isFound(in: sBuf) || p_vat_li.isFound(in: sBuf) ||
                       p_vat_ly_dai_cuong.isFound(in: sBuf) || p_vat_li_dai_cuong.isFound(in: sBuf) {
                        hasPhysics = true
                    }
                }
                if !hasPhysics && flags.contains(.wCo) && p_co_hoc.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.wNhiet) && p_nhiet_hoc.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.wQuang) && p_quang_hoc.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.wDien) && p_dien_tu.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.wDao) && p_dao_dong.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.wSong) && p_song_co.isFound(in: sBuf) { hasPhysics = true }
                if !hasPhysics && flags.contains(.ly) {
                    if p_mon_ly.isFound(in: sBuf) || p_mon_li.isFound(in: sBuf) || p_sbt_ly.isFound(in: sBuf) || p_sbt_li.isFound(in: sBuf) {
                        hasPhysics = true
                    } else if !p_quan_ly.isFound(in: sBuf) && !p_quan_li.isFound(in: sBuf) &&
                        !p_xu_ly.isFound(in: sBuf) && !p_xu_li.isFound(in: sBuf) &&
                        !p_tam_ly.isFound(in: sBuf) && !p_tam_li.isFound(in: sBuf) &&
                        !p_phap_ly.isFound(in: sBuf) && !p_phap_li.isFound(in: sBuf) &&
                        !p_dia_ly.isFound(in: sBuf) && !p_dia_li.isFound(in: sBuf) &&
                        !p_triet_ly.isFound(in: sBuf) && !p_triet_li.isFound(in: sBuf) &&
                        !p_ly_thuyet.isFound(in: sBuf) && !p_li_thuyet.isFound(in: sBuf) &&
                        !p_ly_luan.isFound(in: sBuf) && !p_li_luan.isFound(in: sBuf) &&
                        !p_ly_do.isFound(in: sBuf) && !p_li_do.isFound(in: sBuf) &&
                        !p_hop_ly.isFound(in: sBuf) && !p_hop_li.isFound(in: sBuf) &&
                        !p_dai_ly.isFound(in: sBuf) && !p_dai_li.isFound(in: sBuf) {
                        hasPhysics = true
                    }
                }
            }
            if hasPhysics { return .physics }

            // Chemistry
            var hasChem = flags.contains(.chemistry)
            if !hasChem && flags.contains(.hoa) {
                if p_hoa_hoc.isFound(in: sBuf) || p_mon_hoa.isFound(in: sBuf) ||
                   p_hoa_huu_co.isFound(in: sBuf) || p_hoa_vo_co.isFound(in: sBuf) ||
                   p_hoa_dai_cuong.isFound(in: sBuf) || p_hoa_phan_tich.isFound(in: sBuf) {
                    hasChem = true
                } else if !p_tu_dong_hoa.isFound(in: sBuf) &&
                    !p_tien_hoa.isFound(in: sBuf) &&
                    !p_tieu_hoa.isFound(in: sBuf) &&
                    !p_hoa_don.isFound(in: sBuf) &&
                    !p_van_hoa.isFound(in: sBuf) &&
                    !p_toi_uu_hoa.isFound(in: sBuf) &&
                    !p_chuan_hoa.isFound(in: sBuf) &&
                    !p_cong_nghiep_hoa.isFound(in: sBuf) &&
                    !p_hien_dai_hoa.isFound(in: sBuf) &&
                    !p_ao_hoa.isFound(in: sBuf) &&
                    !p_so_hoa.isFound(in: sBuf) &&
                    !p_hoa_binh.isFound(in: sBuf) &&
                    !p_hoa_hop.isFound(in: sBuf) &&
                    !p_hoa_than.isFound(in: sBuf) {
                    hasChem = true
                }
            }
            if hasChem { return .chemistry }

            // Biology
            var hasBio = flags.contains(.biology)
            if !hasBio {
                if flags.contains(.wY) && p_y_hoc.isFound(in: sBuf) { hasBio = true }
                else if flags.contains(.wDi) && p_di_truyen.isFound(in: sBuf) { hasBio = true }
                else if flags.contains(.wTe) && p_te_bao.isFound(in: sBuf) { hasBio = true }
                else if flags.contains(.wVi) && p_vi_sinh.isFound(in: sBuf) { hasBio = true }
                else if flags.contains(.wTieu) && p_tieu_hoa.isFound(in: sBuf) { hasBio = true }
                else if flags.contains(.sinh) {
                    if p_sinh_hoc.isFound(in: sBuf) || p_mon_sinh.isFound(in: sBuf) || p_sinh_thai.isFound(in: sBuf) {
                        hasBio = true
                    } else if !p_hoc_sinh.isFound(in: sBuf) && !p_sinh_vien.isFound(in: sBuf) && !p_sinh_hoat.isFound(in: sBuf) {
                        hasBio = true
                    }
                }
            }
            if hasBio { return .biology }

            // History
            if flags.contains(.history) { return .history }
            if flags.contains(.su) {
                let isLichSuManners = p_lich_su_trong.isFound(in: sBuf) ||
                    p_giao_tiep.isFound(in: sBuf) ||
                    p_ung_xu.isFound(in: sBuf) ||
                    rawText.contains("lịch sự")
                if !isLichSuManners {
                    if p_lich_su.isFound(in: sBuf) || p_mon_su.isFound(in: sBuf) || !p_su_dung.isFound(in: sBuf) {
                        return .history
                    }
                }
            }

            // Literature
            if flags.contains(.literature) { return .literature }
            if flags.contains(.van) {
                if p_ngu_van.isFound(in: sBuf) || p_tieng_viet.isFound(in: sBuf) || p_mon_van.isFound(in: sBuf) {
                    return .literature
                }
                if !p_van_phong.isFound(in: sBuf) &&
                    !p_van_hoa.isFound(in: sBuf) &&
                    !p_van_minh.isFound(in: sBuf) &&
                    !p_van_ban.isFound(in: sBuf) &&
                    !p_luan_van.isFound(in: sBuf) {
                    return .literature
                }
            }

            // English
            if flags.contains(.english) { return .english }
            if flags.contains(.anh) {
                if p_tieng_anh.isFound(in: sBuf) || p_mon_anh.isFound(in: sBuf) {
                    return .english
                }
                if !p_hinh_anh.isFound(in: sBuf) &&
                    !p_am_thanh.isFound(in: sBuf) &&
                    !p_thay.isFound(in: sBuf) &&
                    !p_co.isFound(in: sBuf) &&
                    !rawText.contains("cô") &&
                    !p_gv.isFound(in: sBuf) {
                    return .english
                }
            }

            // Computer Science
            if flags.contains(.cs) { return .computerScience }
            var hasCs = false
            if flags.contains(.tin) {
                if p_tin_hoc.isFound(in: sBuf) || p_mon_tin.isFound(in: sBuf) {
                    hasCs = true
                } else if !p_thong_tin.isFound(in: sBuf) &&
                    !p_ban_tin.isFound(in: sBuf) &&
                    !p_tin_tuc.isFound(in: sBuf) &&
                    !p_niem_tin.isFound(in: sBuf) &&
                    !flags.contains(.tu) {
                    hasCs = true
                }
            }
            if !hasCs {
                if flags.contains(.wLap) && p_lap_trinh.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wDi) && p_di_dong.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wCong) && p_cong_nghe_thong_tin.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wThuat) && p_thuat_toan.isFound(in: sBuf) { hasCs = true }
                else if (flags.contains(.wCo) && p_co_so_du_lieu.isFound(in: sBuf)) || (flags.contains(.wCau) && p_cau_truc_du_lieu.isFound(in: sBuf)) { hasCs = true }
                else if flags.contains(.wKhoa) && p_khoa_hoc_may_tinh.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wTri) && p_tri_tue_nhan_tao.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wMachine) && p_machine_learning.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wHe) && p_he_dieu_hanh.isFound(in: sBuf) { hasCs = true }
                else if flags.contains(.wKien) && p_kien_truc_may_tinh.isFound(in: sBuf) { hasCs = true }
            }
            if hasCs { return .computerScience }

            // Defense
            if flags.contains(.defense) { return .defenseEducation }
            if flags.contains(.wQuoc) || flags.contains(.wQuan) || flags.contains(.wGiao) {
                if p_giao_duc_quoc_phong.isFound(in: sBuf) ||
                    p_quoc_phong_an_ninh.isFound(in: sBuf) ||
                    p_an_ninh_quoc_phong.isFound(in: sBuf) ||
                    p_quan_su.isFound(in: sBuf) ||
                    p_giao_duc_qp.isFound(in: sBuf) {
                    return .defenseEducation
                }
            }

            // Local
            if flags.contains(.local) { return .localEducation }
            if flags.contains(.wGiao) {
                if p_giao_duc_dia_phuong.isFound(in: sBuf) || p_giao_duc_dp.isFound(in: sBuf) {
                    return .localEducation
                }
            }

            // Experiential
            if flags.contains(.experiential) { return .experientialActivities }
            if flags.contains(.wHoat) || flags.contains(.wHuong) || flags.contains(.sinh) {
                if p_hoat_dong_trai_nghiem.isFound(in: sBuf) ||
                    p_huong_nghiep.isFound(in: sBuf) ||
                    p_sinh_hoat_duoi_co.isFound(in: sBuf) ||
                    p_sinh_hoat_lop.isFound(in: sBuf) {
                    return .experientialActivities
                }
            }

            return nil
        } ?? nil
    }

    private static func computeCategory(for courseName: String, title: String? = nil) -> SubjectCategory {
        if let title, !title.isEmpty {
            if let matched = classifyCandidate(rawText: title) {
                return matched
            }
            return category(for: courseName, title: nil)
        }
        if let matched = classifyCandidate(rawText: courseName) {
            return matched
        }
        return .other
    }

    public static func icon(for category: SubjectCategory) -> String {
        switch category {
        case .computerScience: return "laptopcomputer"
        case .math: return "function"
        case .english: return "globe.americas"
        case .literature: return "book.pages"
        case .physics: return "atom"
        case .chemistry: return "flask"
        case .biology: return "leaf"
        case .history: return "building.columns"
        case .defenseEducation: return "shield.fill"
        case .localEducation: return "map"
        case .experientialActivities: return "sparkles"
        case .other: return "book.closed"
        }
    }

    public static func icon(for courseName: String, title: String? = nil) -> String {
        icon(for: category(for: courseName, title: title))
    }

    public static func themeColor(for category: SubjectCategory) -> Color {
        standardThemes[category]?.themeColor ?? Color(red: 0.40, green: 0.52, blue: 0.64)
    }

    public static func themeColor(for courseName: String, title: String? = nil) -> Color {
        themeColor(for: category(for: courseName, title: title))
    }

    public static func bannerBackground(for category: SubjectCategory) -> Color {
        switch category {
        case .computerScience: return Color(red: 0.06, green: 0.58, blue: 0.50)
        case .math: return Color(red: 0.88, green: 0.50, blue: 0.08)
        case .english: return Color(red: 0.12, green: 0.48, blue: 0.88)
        case .literature: return Color(red: 0.86, green: 0.34, blue: 0.20)
        case .physics: return Color(red: 0.40, green: 0.34, blue: 0.84)
        case .chemistry: return Color(red: 0.80, green: 0.24, blue: 0.60)
        case .biology: return Color(red: 0.14, green: 0.60, blue: 0.34)
        case .history: return Color(red: 0.80, green: 0.46, blue: 0.14)
        case .defenseEducation: return Color(red: 0.12, green: 0.50, blue: 0.22)
        case .localEducation: return Color(red: 0.04, green: 0.50, blue: 0.46)
        case .experientialActivities: return Color(red: 0.88, green: 0.36, blue: 0.10)
        case .other: return Color(red: 0.30, green: 0.44, blue: 0.60)
        }
    }

    public static func bannerBackground(for courseName: String, title: String? = nil) -> Color {
        bannerBackground(for: category(for: courseName, title: title))
    }
}

public struct CourseColorHelper {
    public static func color(for courseName: String, title: String? = nil) -> Color {
        SubjectArtHelper.themeColor(for: courseName, title: title)
    }
}

public struct SubjectArtBadgeView: View, Equatable {
    let courseName: String
    var title: String? = nil
    var category: SubjectCategory? = nil
    var size: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    public init(courseName: String, title: String? = nil, size: CGFloat = 20) {
        self.courseName = courseName
        self.title = title
        self.category = nil
        self.size = size
    }

    public init(category: SubjectCategory, size: CGFloat = 20) {
        self.courseName = ""
        self.title = nil
        self.category = category
        self.size = size
    }

    public static func == (lhs: SubjectArtBadgeView, rhs: SubjectArtBadgeView) -> Bool {
        lhs.courseName == rhs.courseName && lhs.title == rhs.title && lhs.category == rhs.category && lhs.size == rhs.size
    }

    public var body: some View {
        let visualTheme: SubjectArtHelper.VisualTheme = {
            if let cat = category {
                return SubjectArtHelper.theme(for: cat)
            }
            return SubjectArtHelper.theme(for: courseName, title: title)
        }()
        let cornerRadius = size * 0.28
        let isDark = colorScheme == .dark
        let bgOpacity: Double = isDark ? 0.28 : 0.16
        let strokeOpacity: Double = isDark ? 0.55 : 0.38

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(visualTheme.themeColor.opacity(bgOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(visualTheme.themeColor.opacity(strokeOpacity), lineWidth: 1)
                )
                .frame(width: size, height: size)

            Image(systemName: visualTheme.icon)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(visualTheme.themeColor)
        }
    }
}

public struct ClassroomSubjectBanner: View {
    let item: Coursework
    @State private var isHovered: Bool = false

    public init(item: Coursework) {
        self.item = item
    }

    public var body: some View {
        let visualTheme = SubjectArtHelper.theme(for: item.courseName, title: item.title)
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            visualTheme.bannerBackground,
                            visualTheme.bannerBackground.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                #if os(iOS)
                .frame(minHeight: 88)
                #else
                .frame(minHeight: 110)
                #endif
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.35 : 0.18), lineWidth: 1)
                )
                .shadow(color: visualTheme.bannerBackground.opacity(0.18), radius: 8, x: 0, y: 3)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        SubjectArtBadgeView(courseName: item.courseName, size: 26)
                        Text(item.courseName)
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundStyle(.white.opacity(0.95))
                    }

                    Text(item.title)
                        .font(.system(size: 21.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5.5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.conciseDueString)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.96))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(Color.white.opacity(0.16))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.8)
                    )
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                #if os(iOS)
                let artWidth: CGFloat = 72
                let artHeight: CGFloat = 65
                #else
                let artWidth: CGFloat = 88
                let artHeight: CGFloat = 80
                #endif

                ZStack {
                    RealSubjectArtScene(courseName: item.courseName)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .opacity(0.85)

                    ChunkyEmberCharacterView(
                        emotion: item.isCompleted ? .celebrating : (item.isUrgent ? .stressed : .normal),
                        size: artHeight * 0.88
                    )
                    .scaleEffect(isHovered ? 1.08 : 1.0)
                    .offset(x: isHovered ? -2 : 0, y: isHovered ? -2 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isHovered)
                }
                .frame(width: artWidth, height: artHeight)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                isHovered = hovering
            }
        }
        #endif
    }
}

public struct WidgetCardBackground: View {
    var cornerRadius: CGFloat = 16

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ChunkyTheme.sheetBg)
            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
            )
    }
}

public struct WidgetAppleGlassBackground: View {
    var cornerRadius: CGFloat = 20

    public init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        #if (os(macOS) || os(iOS)) && compiler(>=6.4)
        if #available(iOS 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        #elseif os(macOS) || os(iOS)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
        #else
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white)
        #endif
    }
}

public struct WidgetAtmosphereBackground: View {
    var cornerRadius: CGFloat = 20

    public init(cornerRadius: CGFloat = 20, hasUrgentTask: Bool = false) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        WidgetAppleGlassBackground(cornerRadius: cornerRadius)
    }
}

public struct CourseTagView: View {
    let name: String

    public init(name: String, showDot: Bool = false) {
        self.name = name
    }

    public var body: some View {
        let visualTheme = SubjectArtHelper.theme(for: name)
        HStack(spacing: 4) {
            Image(systemName: visualTheme.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(visualTheme.themeColor)
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

public struct DueBadgeView: View, Equatable {
    let item: Coursework
    var compact: Bool = false

    public init(item: Coursework, compact: Bool = false) {
        self.item = item
        self.compact = compact
    }

    public static func == (lhs: DueBadgeView, rhs: DueBadgeView) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.status == rhs.item.status &&
        lhs.item.dueDate == rhs.item.dueDate &&
        lhs.item.isCompleted == rhs.item.isCompleted &&
        lhs.item.isOverdue == rhs.item.isOverdue &&
        lhs.compact == rhs.compact
    }

    private var badgeColor: Color {
        if item.isCompleted {
            return Color(red: 0.12, green: 0.62, blue: 0.35)
        } else if item.isOverdue || item.isPast {
            return Color(red: 0.90, green: 0.22, blue: 0.21)
        } else if item.isDueToday {
            return Color(red: 0.90, green: 0.48, blue: 0.08)
        } else if item.isDueTomorrow {
            return Color(red: 0.14, green: 0.48, blue: 0.92)
        } else {
            return Color(red: 0.45, green: 0.50, blue: 0.58)
        }
    }

    private var badgeText: String {
        if compact {
            return item.compactDueString
        } else {
            return item.friendlyDueString
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            if item.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .bold))
            } else if item.isOverdue || item.isPast {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
            } else {
                Image(systemName: "clock")
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
            }

            Text(badgeText)
                .font(.system(size: compact ? 13.5 : 14.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, compact ? 8.5 : 10.5)
        .padding(.vertical, compact ? 4 : 5)
        .appleLiquidGlassSurface(
            style: .tint(badgeColor.opacity(0.14)),
            in: RoundedRectangle(cornerRadius: 6, style: .continuous),
            isEnabled: !compact
        ) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(badgeColor.opacity(0.12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(badgeColor.opacity(0.25), lineWidth: 1)
        )
    }
}

public struct WidgetEmptyStateView: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            ChunkyEmberCharacterView(emotion: .sleeping, size: 52)

            VStack(alignment: .leading, spacing: 2.5) {
                Text("Ngày mai không có bài!")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả bài tập đã hoàn thành.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }
}

public struct RisoMockData {
    public static var tomorrowEvening: Date {
        let calendar = Calendar.autoupdatingCurrent
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 23
        comp.minute = 59
        return calendar.date(from: comp) ?? Date()
    }

    public static var tomorrowAfternoon: Date {
        let calendar = Calendar.autoupdatingCurrent
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 17
        comp.minute = 30
        return calendar.date(from: comp) ?? Date()
    }

    public static var todayEvening: Date {
        let calendar = Calendar.autoupdatingCurrent
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.hour = 23
        comp.minute = 55
        return calendar.date(from: comp) ?? Date()
    }

    public static let historyTask = Coursework(
        id: "task-su",
        courseId: "11-tin",
        courseName: "Sử",
        title: "Cách mạng tháng Tám và sự ra đời của nước VNDCCH",
        description: "Lập bảng niên biểu các mốc sự kiện chính trong tuần 5",
        dueDate: tomorrowEvening
    )

    public static let physicsTask = Coursework(
        id: "task-ly",
        courseId: "11-tin",
        courseName: "Lý",
        title: "Hiện tượng cảm ứng điện từ và định luật Faraday (Bài 1-5 SBT)",
        description: "Làm vào vở bài tập, chuẩn bị bài thí nghiệm thực hành",
        dueDate: tomorrowAfternoon
    )

    public static let chemistryTask = Coursework(
        id: "task-hoa",
        courseId: "11-tin",
        courseName: "Hóa",
        title: "Hoàn thành sơ đồ nhận biết hợp chất hữu cơ có nhóm chức",
        description: nil,
        dueDate: tomorrowEvening
    )

    public static let literatureTask = Coursework(
        id: "task-van",
        courseId: "11-tin",
        courseName: "Ngữ văn",
        title: "Viết đoạn văn 200 chữ phân tích nghệ thuật trào phúng Vũ Trọng Phụng",
        description: nil,
        dueDate: tomorrowEvening
    )

    public static let mathTask = Coursework(
        id: "task-toan",
        courseId: "11-tin",
        courseName: "Toán",
        title: "Giải tích: Đạo hàm cấp hai và khảo sát sự biến thiên của hàm số",
        dueDate: tomorrowEvening
    )

    public static let longTitleTask = Coursework(
        id: "task-long",
        courseId: "11-tin",
        courseName: "Tin học",
        title: "Lập trình thuật toán sắp xếp nhanh (QuickSort) và tìm kiếm nhị phân nâng cao trên mảng số nguyên",
        dueDate: tomorrowEvening
    )

    public static let fourTasks: [Coursework] = [
        historyTask,
        physicsTask,
        chemistryTask,
        literatureTask
    ]

    public static let manyTasks: [Coursework] = [
        physicsTask,
        historyTask,
        chemistryTask,
        literatureTask,
        mathTask
    ]

    public static let partiallyCompletedTasks: [Coursework] = [
        Coursework(
            id: "task-done-1",
            courseId: "11-tin",
            courseName: "Sử",
            title: "Cách mạng tháng Tám và sự ra đời của nước VNDCCH",
            dueDate: tomorrowEvening,
            status: .turnedIn
        ),
        Coursework(
            id: "task-done-2",
            courseId: "11-tin",
            courseName: "Hóa",
            title: "Hoàn thành sơ đồ nhận biết hợp chất hữu cơ có nhóm chức",
            dueDate: tomorrowEvening,
            status: .turnedIn
        ),
        physicsTask,
        literatureTask
    ]
}

public typealias ChunkyMockData = RisoMockData

public enum WidgetFontSystem {
    public static func counter(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func sectionHeader(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func courseTitle(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    public static func statusTag(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    public static func meta(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

public extension Coursework {
    var badgeCode: String {
        SubjectArtHelper.badgeCode(for: courseName, title: title)
    }
    var subjectCategory: SubjectCategory {
        SubjectArtHelper.category(for: courseName, title: title)
    }
}
