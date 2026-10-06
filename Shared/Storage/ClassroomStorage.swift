import Foundation
import WidgetKit

public final class ClassroomStorage: @unchecked Sendable {
    public static let shared = ClassroomStorage()
    public static let appGroupId = "group.com.phucta.classroom"

    private let userDefaults: UserDefaults
    private let coursesKey = "cached_classroom_courses"
    private let courseworkKey = "cached_classroom_coursework"
    private let coursesTimestampKey = "cached_classroom_courses_timestamp"
    private let courseworkTimestampKey = "cached_classroom_coursework_timestamp"
    private let lastSyncKey = "cached_classroom_last_sync"
    private let userEmailKey = "cached_classroom_user_email"

    private var cachedCourses: [Course]?
    private var cachedCoursesTimestamp: Double = 0
    private var cachedCoursework: [Coursework]?
    private var cachedCourseworkTimestamp: Double = 0
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
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedCourses = courses
        cachedCoursesTimestamp = timestamp
        lock.unlock()

        if let encoded = try? JSONEncoder().encode(courses) {
            userDefaults.set(encoded, forKey: coursesKey)
            userDefaults.set(timestamp, forKey: coursesTimestampKey)
            UserDefaults.standard.set(encoded, forKey: coursesKey)
            UserDefaults.standard.set(timestamp, forKey: coursesTimestampKey)
        }
        notifyWidgetReload()
    }

    public func loadCourses() -> [Course] {
        let latestTimestamp = userDefaults.double(forKey: coursesTimestampKey)
        lock.lock()
        if let cached = cachedCourses, latestTimestamp > 0 && latestTimestamp == cachedCoursesTimestamp {
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
        cachedCoursesTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970
        lock.unlock()
        return result
    }

    public func saveCoursework(_ items: [Coursework]) {
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedCoursework = items
        cachedCourseworkTimestamp = timestamp
        lock.unlock()

        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: courseworkKey)
            userDefaults.set(timestamp, forKey: courseworkTimestampKey)
            UserDefaults.standard.set(encoded, forKey: courseworkKey)
            UserDefaults.standard.set(timestamp, forKey: courseworkTimestampKey)
        }
        saveLastSyncTime(Date())
        notifyWidgetReload()
    }

    public func loadCoursework() -> [Coursework] {
        let latestTimestamp = userDefaults.double(forKey: courseworkTimestampKey)
        lock.lock()
        if let cached = cachedCoursework, latestTimestamp > 0 && latestTimestamp == cachedCourseworkTimestamp {
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
        cachedCourseworkTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970
        lock.unlock()
        return result
    }

    public func getPendingCoursework() -> [Coursework] {
        let allItems = loadCoursework()
        let activeCourseIds = Set(loadCourses().filter(\.isSelectedForWidget).map(\.id))

        return allItems
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { !$0.isCompleted }
            .sorted { (first, second) -> Bool in
                switch (first.dueDate, second.dueDate) {
                case let (d1?, d2?):
                    if d1 != d2 { return d1 < d2 }
                    return first.title.localizedStandardCompare(second.title) == .orderedAscending
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return first.title.localizedStandardCompare(second.title) == .orderedAscending
                }
            }
    }

    public func getTodayAndTomorrowCoursework() -> [Coursework] {
        getTomorrowCoursework(includeCompleted: true)
    }

    public func getTomorrowCoursework(includeCompleted: Bool = true) -> [Coursework] {
        let allItems = loadCoursework()
        let activeCourseIds = Set(loadCourses().filter(\.isSelectedForWidget).map(\.id))
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        return allItems
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { includeCompleted ? true : !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= startOfTomorrow && dueDate < startOfDayAfter
            }
            .sorted { (first, second) -> Bool in
                if first.isCompleted != second.isCompleted {
                    return !first.isCompleted
                }
                switch (first.dueDate, second.dueDate) {
                case let (d1?, d2?):
                    if d1 != d2 { return d1 < d2 }
                    return first.title.localizedStandardCompare(second.title) == .orderedAscending
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return first.title.localizedStandardCompare(second.title) == .orderedAscending
                }
            }
    }

    public func updateCourseworkStatuses(ids: Set<String>, newStatus: SubmissionStatus) {
        var currentItems = loadCoursework()
        var changed = false
        for i in currentItems.indices {
            if ids.contains(currentItems[i].id) {
                currentItems[i].status = newStatus
                changed = true
            }
        }
        if changed {
            saveCoursework(currentItems)
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
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 3600)
        let tomorrowDue = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: tomorrow) ?? now.addingTimeInterval(26 * 3600)
        let tomorrowEveningDue = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: tomorrow) ?? now.addingTimeInterval(28 * 3600)
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
                dueDate: tomorrowEveningDue,
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
