import Foundation
import WidgetKit

public final class ClassroomStorage: @unchecked Sendable {
    public static let shared = ClassroomStorage()
    public static let appGroupId = "group.com.phucta.classroom"

    private let userDefaults: UserDefaults
    private let coursesKey = "cached_classroom_courses"
    private let courseworkKey = "cached_classroom_coursework"
    private let lastSyncKey = "cached_classroom_last_sync"
    private let userEmailKey = "cached_classroom_user_email"

    private var cachedCourses: [Course]?
    private var cachedCoursework: [Coursework]?
    private let lock = NSLock()

    private init() {
        if let sharedDefaults = UserDefaults(suiteName: ClassroomStorage.appGroupId) {
            self.userDefaults = sharedDefaults
        } else {
            self.userDefaults = .standard
        }

        ensureInitialData()
    }

    public func saveCourses(_ courses: [Course]) {
        lock.lock()
        cachedCourses = courses
        lock.unlock()

        if let encoded = try? JSONEncoder().encode(courses) {
            userDefaults.set(encoded, forKey: coursesKey)
            UserDefaults.standard.set(encoded, forKey: coursesKey)
        }
    }

    public func loadCourses() -> [Course] {
        lock.lock()
        if let cached = cachedCourses {
            lock.unlock()
            return cached
        }
        lock.unlock()

        var loaded: [Course]?
        if let data = userDefaults.data(forKey: coursesKey) {
            loaded = try? JSONDecoder().decode([Course].self, from: data)
        } else if let data = UserDefaults.standard.data(forKey: coursesKey) {
            loaded = try? JSONDecoder().decode([Course].self, from: data)
        }

        let result = loaded ?? ClassroomStorage.mockCourses
        lock.lock()
        cachedCourses = result
        lock.unlock()
        return result
    }

    public func saveCoursework(_ items: [Coursework]) {
        lock.lock()
        cachedCoursework = items
        lock.unlock()

        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: courseworkKey)
            UserDefaults.standard.set(encoded, forKey: courseworkKey)
        }
        saveLastSyncTime(Date())
        notifyWidgetReload()
    }

    public func loadCoursework() -> [Coursework] {
        lock.lock()
        if let cached = cachedCoursework {
            lock.unlock()
            return cached
        }
        lock.unlock()

        var loaded: [Coursework]?
        if let data = userDefaults.data(forKey: courseworkKey) {
            loaded = try? JSONDecoder().decode([Coursework].self, from: data)
        } else if let data = UserDefaults.standard.data(forKey: courseworkKey) {
            loaded = try? JSONDecoder().decode([Coursework].self, from: data)
        }

        let result = loaded ?? ClassroomStorage.mockCoursework
        lock.lock()
        cachedCoursework = result
        lock.unlock()
        return result
    }

    public func getPendingCoursework() -> [Coursework] {
        let allItems = loadCoursework()
        let activeCourseIds = Set(loadCourses().filter(\.isSelectedForWidget).map(\.id))

        return allItems
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .sorted { (first, second) -> Bool in
                guard let d1 = first.dueDate else { return false }
                guard let d2 = second.dueDate else { return true }
                if d1 != d2 {
                    return d1 < d2
                }
                return first.title < second.title
            }
    }

    public func getTodayAndTomorrowCoursework() -> [Coursework] {
        let allItems = loadCoursework()
        let activeCourseIds = Set(loadCourses().filter(\.isSelectedForWidget).map(\.id))
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        return allItems
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= startOfToday && dueDate < dayAfterTomorrow
            }
            .sorted { (first, second) -> Bool in
                guard let d1 = first.dueDate else { return false }
                guard let d2 = second.dueDate else { return true }
                if d1 != d2 {
                    return d1 < d2
                }
                return first.title < second.title
            }
    }

    public func saveLastSyncTime(_ date: Date) {
        userDefaults.set(date.timeIntervalSince1970, forKey: lastSyncKey)
    }

    public func loadLastSyncTime() -> Date? {
        let timestamp = userDefaults.double(forKey: lastSyncKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    public func saveUserEmail(_ email: String?) {
        userDefaults.set(email, forKey: userEmailKey)
    }

    public func loadUserEmail() -> String? {
        userDefaults.string(forKey: userEmailKey)
    }

    public func notifyWidgetReload() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func ensureInitialData() {
        if userDefaults.data(forKey: courseworkKey) == nil {
            saveCourses(ClassroomStorage.mockCourses)
            saveCoursework(ClassroomStorage.mockCoursework)
        }
    }

    public static let mockCourses: [Course] = [
        Course(id: "c1", name: "Nhập môn Lập trình", section: "CS101", descriptionHeading: "Khoa học Máy tính", isSelectedForWidget: true),
        Course(id: "c2", name: "Tiếng Anh Tổng quát", section: "ENG01", descriptionHeading: "Kỹ năng Giao tiếp & Thuyết trình", isSelectedForWidget: true),
        Course(id: "c3", name: "Kỹ năng Làm việc nhóm", section: "SKL02", descriptionHeading: "Kỹ năng mềm & Quản lý thời gian", isSelectedForWidget: true),
        Course(id: "c4", name: "Thiết kế Giao diện", section: "DES03", descriptionHeading: "Giao diện & Trải nghiệm người dùng", isSelectedForWidget: true)
    ]

    public static var mockCoursework: [Coursework] {
        let calendar = Calendar.current
        let now = Date()
        let todayDue = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now.addingTimeInterval(4 * 3600)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 3600)
        let tomorrowDue = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: tomorrow) ?? now.addingTimeInterval(26 * 3600)
        let inThreeDays = calendar.date(byAdding: .day, value: 3, to: now) ?? now.addingTimeInterval(72 * 3600)
        let inFiveDays = calendar.date(byAdding: .day, value: 5, to: now) ?? now.addingTimeInterval(120 * 3600)

        return [
            Coursework(
                id: "cw1",
                courseId: "c1",
                courseName: "Nhập môn Lập trình",
                title: "Bài tập thực hành tuần 1",
                description: """
                Yêu cầu hoàn thành bài tập tuần 1:
                1. Đọc kỹ tài liệu và yêu cầu đề bài được đính kèm.
                2. Hoàn thành phần bài tập theo đúng hướng dẫn.
                3. Kiểm tra lại kết quả trước khi nộp.
                4. Nộp bài trực tiếp qua hệ thống trước hạn chót.
                """,
                alternateLink: "https://classroom.google.com",
                dueDate: todayDue,
                status: .pending,
                maxPoints: 10
            ),
            Coursework(
                id: "cw2",
                courseId: "c2",
                courseName: "Tiếng Anh Tổng quát",
                title: "Bài luận ngắn tuần 2",
                description: """
                Nội dung bài tập tuần 2:
                - Viết bài luận ngắn khoảng 300 - 500 từ theo chủ đề đã giao.
                - Trình bày rõ ràng, mạch lạc và kiểm tra lỗi chính tả trước khi nộp.
                - Đính kèm tệp văn bản hoặc liên kết tài liệu trực tiếp vào bài tập.
                """,
                alternateLink: "https://classroom.google.com",
                dueDate: tomorrowDue,
                status: .pending,
                maxPoints: 100
            ),
            Coursework(
                id: "cw3",
                courseId: "c3",
                courseName: "Kỹ năng Làm việc nhóm",
                title: "Báo cáo tiến độ làm việc nhóm",
                description: """
                Nội dung báo cáo nhóm:
                1. Tổng hợp kết quả thực hiện các mục tiêu trong tuần vừa qua.
                2. Phân công nhiệm vụ cụ thể cho từng thành viên trong tuần tiếp theo.
                3. Đại diện nhóm nộp báo cáo tổng hợp trước thời hạn quy định.
                """,
                alternateLink: "https://classroom.google.com",
                dueDate: inThreeDays,
                status: .pending,
                maxPoints: 10
            ),
            Coursework(
                id: "cw4",
                courseId: "c4",
                courseName: "Thiết kế Giao diện",
                title: "Đề cương ý tưởng dự án",
                description: """
                Yêu cầu nộp đề cương ý tưởng:
                - Trình bày tóm tắt ý tưởng, mục tiêu và đối tượng sử dụng của dự án.
                - Liệt kê các tính năng chính dự kiến sẽ triển khai.
                - Chuẩn bị slide tóm tắt để trình bày trong buổi học tới.
                """,
                alternateLink: "https://classroom.google.com",
                dueDate: inFiveDays,
                status: .pending,
                maxPoints: 10
            )
        ]
    }
}
