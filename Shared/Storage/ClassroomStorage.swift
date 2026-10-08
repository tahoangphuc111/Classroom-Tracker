import Foundation
import WidgetKit
import os

public final class ClassroomStorage: @unchecked Sendable {
    public static let shared = ClassroomStorage()
    public static var appGroupCandidates: [String] {
        #if os(iOS)
        return [
            "group.com.phucta.classroom",
            "4J32CASZVT.group.com.phucta.classroom",
            "VGWH8K5259.group.com.phucta.classroom"
        ]
        #else
        return [
            "4J32CASZVT.group.com.phucta.classroom",
            "VGWH8K5259.group.com.phucta.classroom",
            "group.com.phucta.classroom"
        ]
        #endif
    }

    public static var appGroupId: String {
        appGroupCandidates.first ?? "group.com.phucta.classroom"
    }

    public lazy var allUserDefaults: [UserDefaults] = {
        var list: [UserDefaults] = []
        for id in ClassroomStorage.appGroupCandidates {
            if let ud = UserDefaults(suiteName: id) {
                list.append(ud)
            }
        }
        list.append(.standard)
        return list
    }()

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
    private let lock = NSRecursiveLock()
    private let ioQueue = DispatchQueue(label: "com.phucta.classroom.storage.io", qos: .utility)
    private let storageInitializedKey = "cached_classroom_storage_initialized"

    public struct ClassroomSharedMetadata: Codable {
        public var userEmail: String?
        public var lastSyncTimestamp: Double?
        public var hasUserLoggedIn: Bool

        public init(userEmail: String? = nil, lastSyncTimestamp: Double? = nil, hasUserLoggedIn: Bool = false) {
            self.userEmail = userEmail
            self.lastSyncTimestamp = lastSyncTimestamp
            self.hasUserLoggedIn = hasUserLoggedIn
        }
    }

    public static var sharedStorageDirectories: [URL] {
        var dirs: [URL] = []
        for id in ClassroomStorage.appGroupCandidates {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
                if !dirs.contains(url) {
                    dirs.append(url)
                }
            }
        }
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportDir = appSupport.appendingPathComponent("ClassroomTracker", isDirectory: true)
            if !dirs.contains(appSupportDir) {
                dirs.append(appSupportDir)
            }
            if !dirs.contains(appSupport) {
                dirs.append(appSupport)
            }
        }
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if !dirs.contains(docs) {
                dirs.append(docs)
            }
        }
        return dirs
    }

    private var allStorageDirectories: [URL] {
        Self.sharedStorageDirectories
    }

    private func writeDataToAllDirectories(_ data: Data, fileName: String) {
        let logger = Logger(subsystem: "com.phucta.ClassroomTracker", category: "storage")
        for dir in allStorageDirectories {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let fileURL = dir.appendingPathComponent(fileName)
                do {
                    try data.write(to: fileURL, options: .atomic)
                } catch {
                    try data.write(to: fileURL, options: [])
                }
                try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileURL.path)
                logger.notice("WROTE \(data.count) bytes of \(fileName, privacy: .public) to \(fileURL.path, privacy: .public)")
            } catch {
                logger.error("Error writing \(fileName, privacy: .public) to \(dir.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public var isAppExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
            || (Bundle.main.bundleIdentifier?.contains("widget") == true)
    }

    public func isMockCoursesData(_ data: Data) -> Bool {
        guard let courses = try? JSONDecoder().decode([Course].self, from: data) else { return false }
        if courses.isEmpty { return true }
        return courses.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
    }

    public func isMockCourseworkData(_ data: Data) -> Bool {
        guard let items = try? JSONDecoder().decode([Coursework].self, from: data) else { return false }
        if items.isEmpty { return true }
        return items.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
    }

    private func readDataFromDirectories(fileName: String) -> Data? {
        let logger = Logger(subsystem: "com.phucta.ClassroomTracker", category: "storage")
        var candidateData: Data? = nil
        for dir in allStorageDirectories {
            let fileURL = dir.appendingPathComponent(fileName)
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            logger.notice("readData check \(fileName, privacy: .public) at \(fileURL.path, privacy: .public) -> exists=\(exists)")
            if exists {
                do {
                    let data = try Data(contentsOf: fileURL)
                    logger.notice("readData read \(data.count) bytes of \(fileName, privacy: .public) at \(dir.path, privacy: .public)")
                    if data.isEmpty {
                        logger.error("readData: file is 0 bytes at \(fileURL.path, privacy: .public)")
                    } else {
                        if fileName == "cached_classroom_courses.json" {
                            let isMock = isMockCoursesData(data)
                            logger.notice("readData courses isMock=\(isMock) for \(dir.path, privacy: .public)")
                            if !isMock { return data }
                        } else if fileName == "cached_classroom_coursework.json" {
                            let isMock = isMockCourseworkData(data)
                            logger.notice("readData coursework isMock=\(isMock) for \(dir.path, privacy: .public)")
                            if !isMock { return data }
                        }
                        if candidateData == nil {
                            candidateData = data
                        }
                    }
                } catch {
                    logger.error("readData FAILED to read \(fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        if let candidateData {
            if isAppExtension {
                if fileName == "cached_classroom_courses.json" && isMockCoursesData(candidateData) {
                    return nil
                }
                if fileName == "cached_classroom_coursework.json" && isMockCourseworkData(candidateData) {
                    return nil
                }
            }
        }
        return candidateData
    }

    public func loadSharedMetadata() -> ClassroomSharedMetadata? {
        if let data = readDataFromDirectories(fileName: "cached_classroom_metadata.json"),
           let metadata = try? JSONDecoder().decode(ClassroomSharedMetadata.self, from: data) {
            return metadata
        }
        return nil
    }

    public func saveSharedMetadata(_ metadata: ClassroomSharedMetadata) {
        if let data = try? JSONEncoder().encode(metadata) {
            writeDataToAllDirectories(data, fileName: "cached_classroom_metadata.json")
        }
    }

    private var cachedHasUserLoggedIn: Bool? = nil

    public var hasUserLoggedIn: Bool {
        if let cached = cachedHasUserLoggedIn {
            return cached
        }
        if let metadata = loadSharedMetadata(), metadata.hasUserLoggedIn {
            cachedHasUserLoggedIn = true
            return true
        }
        if let email = loadUserEmail(), !email.trimmingCharacters(in: .whitespaces).isEmpty {
            cachedHasUserLoggedIn = true
            return true
        }
        for dir in allStorageDirectories {
            let tokenFile = dir.appendingPathComponent("cached_oauth_tokens.json")
            if FileManager.default.fileExists(atPath: tokenFile.path) {
                cachedHasUserLoggedIn = true
                return true
            }
        }
        cachedHasUserLoggedIn = false
        return false
    }

    public func saveUserLoggedIn(_ loggedIn: Bool) {
        lock.lock()
        cachedHasUserLoggedIn = loggedIn
        lock.unlock()
        var metadata = loadSharedMetadata() ?? ClassroomSharedMetadata()
        metadata.hasUserLoggedIn = loggedIn
        saveSharedMetadata(metadata)
    }

    private init() {
        if let candidate = ClassroomStorage.appGroupCandidates.compactMap({ UserDefaults(suiteName: $0) }).first {
            self.userDefaults = candidate
        } else {
            self.userDefaults = .standard
        }

        if !isAppExtension {
            synchronizeAllStorageLayers()
            ensureInitialData()
        }
    }

    public func synchronizeAllStorageLayers() {
        guard !isAppExtension else { return }
        var bestCoursesData: Data?
        var bestCourseworkData: Data?
        var bestEmail: String?
        var bestSyncTime: Double = 0

        if let fData = readDataFromDirectories(fileName: "cached_classroom_courses.json") {
            bestCoursesData = fData
        }
        if let fData = readDataFromDirectories(fileName: "cached_classroom_coursework.json") {
            bestCourseworkData = fData
        }
        if let meta = loadSharedMetadata() {
            if let e = meta.userEmail, !e.isEmpty { bestEmail = e }
            if let t = meta.lastSyncTimestamp, t > 0 { bestSyncTime = t }
        }

        for ud in allUserDefaults {
            if let email = ud.string(forKey: userEmailKey), !email.isEmpty, bestEmail == nil {
                bestEmail = email
            }
            if let cData = ud.data(forKey: coursesKey), !cData.isEmpty {
                if bestCoursesData == nil || (isMockCoursesData(bestCoursesData!) && !isMockCoursesData(cData)) {
                    bestCoursesData = cData
                }
            }
            if let cwData = ud.data(forKey: courseworkKey), !cwData.isEmpty {
                if bestCourseworkData == nil || (isMockCourseworkData(bestCourseworkData!) && !isMockCourseworkData(cwData)) {
                    bestCourseworkData = cwData
                }
            }
            let sTime = ud.double(forKey: lastSyncKey)
            if sTime > bestSyncTime {
                bestSyncTime = sTime
            }
        }

        for ud in allUserDefaults {
            if let bestCoursesData {
                ud.set(bestCoursesData, forKey: coursesKey)
            }
            if let bestCourseworkData {
                ud.set(bestCourseworkData, forKey: courseworkKey)
            }
            if let bestEmail {
                ud.set(bestEmail, forKey: userEmailKey)
            }
            if bestSyncTime > 0 {
                ud.set(bestSyncTime, forKey: lastSyncKey)
            }
        }

        if let bestCoursesData {
            writeDataToAllDirectories(bestCoursesData, fileName: "cached_classroom_courses.json")
        }
        if let bestCourseworkData {
            writeDataToAllDirectories(bestCourseworkData, fileName: "cached_classroom_coursework.json")
        }

        let isUserLogged = (bestEmail != nil && !bestEmail!.isEmpty) || hasUserLoggedIn
        let metadata = ClassroomSharedMetadata(
            userEmail: bestEmail,
            lastSyncTimestamp: bestSyncTime > 0 ? bestSyncTime : Date().timeIntervalSince1970,
            hasUserLoggedIn: isUserLogged
        )
        if let metaData = try? JSONEncoder().encode(metadata) {
            writeDataToAllDirectories(metaData, fileName: "cached_classroom_metadata.json")
        }
    }

    public func saveCourses(_ courses: [Course]) {
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedCourses = courses
        cachedCoursesTimestamp = timestamp
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let encoded = try? JSONEncoder().encode(courses) else { return }

            self.writeDataToAllDirectories(encoded, fileName: "cached_classroom_courses.json")

            for ud in self.allUserDefaults {
                ud.set(encoded, forKey: self.coursesKey)
                ud.set(timestamp, forKey: self.coursesTimestampKey)
            }

            self.notifyWidgetReload()
        }
    }

    public func loadCourses() -> [Course] {
        lock.lock()
        let memoryCached = cachedCourses
        let memoryTimestamp = cachedCoursesTimestamp
        lock.unlock()

        let latestTimestamp = allUserDefaults.map { $0.double(forKey: coursesTimestampKey) }.max() ?? 0

        if let memoryCached, memoryTimestamp > 0, memoryTimestamp >= latestTimestamp {
            return memoryCached
        }

        var loaded: [Course]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_courses.json") {
            loaded = try? JSONDecoder().decode([Course].self, from: data)
        }
        for ud in allUserDefaults {
            if let data = ud.data(forKey: coursesKey),
               let decoded = try? JSONDecoder().decode([Course].self, from: data),
               !decoded.isEmpty {
                let currentIsMock = loaded.map { items in items.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil } } ?? true
                let newIsMock = decoded.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
                if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                    loaded = decoded
                }
            }
        }

        // Never show mock data in widget extensions
        if isAppExtension, let loadedItems = loaded {
            let allMock = loadedItems.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
            if allMock {
                loaded = nil
            }
        }

        let result: [Course]
        if let loaded, !loaded.isEmpty {
            result = loaded
        } else {
            result = []
        }
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        cachedCourses = result
        cachedCoursesTimestamp = effectiveTimestamp
        lock.unlock()

        return result
    }

    public func saveCoursework(_ items: [Coursework]) {
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedCoursework = items
        cachedCourseworkTimestamp = timestamp
        lock.unlock()

        let syncDate = Date()
        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let encoded = try? JSONEncoder().encode(items) else { return }

            self.writeDataToAllDirectories(encoded, fileName: "cached_classroom_coursework.json")

            for ud in self.allUserDefaults {
                ud.set(encoded, forKey: self.courseworkKey)
                ud.set(timestamp, forKey: self.courseworkTimestampKey)
            }

            self.saveLastSyncTime(syncDate)
            self.notifyWidgetReload()
        }
    }

    public func loadCoursework() -> [Coursework] {
        lock.lock()
        let memoryCached = cachedCoursework
        let memoryTimestamp = cachedCourseworkTimestamp
        lock.unlock()

        let latestTimestamp = allUserDefaults.map { $0.double(forKey: courseworkTimestampKey) }.max() ?? 0

        if let memoryCached, memoryTimestamp > 0, memoryTimestamp >= latestTimestamp {
            return memoryCached
        }

        var loaded: [Coursework]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_coursework.json") {
            loaded = try? JSONDecoder().decode([Coursework].self, from: data)
        }
        for ud in allUserDefaults {
            if let data = ud.data(forKey: courseworkKey),
               let decoded = try? JSONDecoder().decode([Coursework].self, from: data),
               !decoded.isEmpty {
                let currentIsMock = loaded.map { items in items.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil } } ?? true
                let newIsMock = decoded.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
                if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                    loaded = decoded
                }
            }
        }

        // Never show mock data in widget extensions
        if isAppExtension, let loadedItems = loaded {
            let allMock = loadedItems.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
            if allMock {
                loaded = nil
            }
        }

        let result: [Coursework]
        if let loaded, !loaded.isEmpty {
            result = loaded
        } else {
            result = []
        }
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        cachedCoursework = result
        cachedCourseworkTimestamp = effectiveTimestamp
        lock.unlock()

        return result
    }

    private func filterItemsByActiveCourses(_ items: [Coursework]) -> [Coursework] {
        let loadedCourses = loadCourses()
        guard !loadedCourses.isEmpty else { return items }

        let allCourseIds = Set(loadedCourses.map(\.id))
        let itemsBelongToLoadedCourses = items.contains { allCourseIds.contains($0.courseId) }

        if itemsBelongToLoadedCourses {
            let activeCourseIds = Set(loadedCourses.filter(\.isSelectedForWidget).map(\.id))
            return items.filter { activeCourseIds.contains($0.courseId) }
        }

        return items
    }

    private func sortCoursework(_ items: [Coursework]) -> [Coursework] {
        items.sorted { (first, second) -> Bool in
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

    public func getPendingCoursework() -> [Coursework] {
        let allItems = loadCoursework()
        let relevant = filterItemsByActiveCourses(allItems)

        return relevant
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

    public func getTodayAndTomorrowCoursework(includeCompleted: Bool = true) -> [Coursework] {
        let allItems = loadCoursework()
        let relevant = filterItemsByActiveCourses(allItems)
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        let filtered = relevant
            .filter { includeCompleted ? true : !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= startOfToday && dueDate < startOfDayAfter
            }

        return sortCoursework(filtered)
    }

    public func getTomorrowCoursework(includeCompleted: Bool = true) -> [Coursework] {
        let allItems = loadCoursework()
        let relevant = filterItemsByActiveCourses(allItems)
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        // 1. Due tomorrow (The primary target for Báo bài)
        let tomorrowFiltered = relevant
            .filter { includeCompleted ? true : !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= startOfTomorrow && dueDate < startOfDayAfter
            }

        if !tomorrowFiltered.isEmpty {
            return sortCoursework(tomorrowFiltered)
        }

        // Fallback 1: Overdue incomplete tasks (missed deadlines)
        let overdue = relevant
            .filter { !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate < now
            }

        if !overdue.isEmpty {
            return sortCoursework(overdue)
        }

        // Fallback 2: Incomplete tasks due today that are still unsubmitted
        let todayIncomplete = relevant
            .filter { !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= now && dueDate < startOfTomorrow
            }

        if !todayIncomplete.isEmpty {
            return sortCoursework(todayIncomplete)
        }

        // Fallback 3: Next upcoming tasks in 2+ days
        let laterUpcoming = relevant
            .filter { includeCompleted ? true : !$0.isCompleted }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= startOfDayAfter
            }

        if !laterUpcoming.isEmpty {
            return sortCoursework(laterUpcoming)
        }

        // Fallback 4: Undated tasks
        let undated = relevant
            .filter { includeCompleted ? true : !$0.isCompleted }
            .filter { $0.dueDate == nil }

        return sortCoursework(undated)
    }

    public func clearAllData() {
        lock.lock()
        cachedCourses = nil
        cachedCoursesTimestamp = 0
        cachedCoursework = nil
        cachedCourseworkTimestamp = 0
        cachedHasUserLoggedIn = nil
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            for dir in self.allStorageDirectories {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_courses.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_coursework.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_metadata.json"))
            }
            self.userDefaults.removeObject(forKey: self.coursesKey)
            self.userDefaults.removeObject(forKey: self.courseworkKey)
            self.userDefaults.removeObject(forKey: self.coursesTimestampKey)
            self.userDefaults.removeObject(forKey: self.courseworkTimestampKey)
            self.userDefaults.removeObject(forKey: self.lastSyncKey)
            self.userDefaults.removeObject(forKey: self.userEmailKey)

            UserDefaults.standard.removeObject(forKey: self.coursesKey)
            UserDefaults.standard.removeObject(forKey: self.courseworkKey)
            UserDefaults.standard.removeObject(forKey: self.coursesTimestampKey)
            UserDefaults.standard.removeObject(forKey: self.courseworkTimestampKey)

            self.notifyWidgetReload()
        }
    }

    public func updateCourseworkStatuses(ids: Set<String>, newStatus: SubmissionStatus) {
        lock.lock()
        defer { lock.unlock() }

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
        let timestamp = date.timeIntervalSince1970
        var metadata = loadSharedMetadata() ?? ClassroomSharedMetadata()
        metadata.lastSyncTimestamp = timestamp
        saveSharedMetadata(metadata)
        for ud in allUserDefaults {
            ud.set(timestamp, forKey: lastSyncKey)
        }
    }

    public func loadLastSyncTime() -> Date? {
        if let metaStamp = loadSharedMetadata()?.lastSyncTimestamp, metaStamp > 0 {
            return Date(timeIntervalSince1970: metaStamp)
        }
        for ud in allUserDefaults {
            let timestamp = ud.double(forKey: lastSyncKey)
            if timestamp > 0 {
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        return nil
    }

    public func saveUserEmail(_ email: String?) {
        let isPresent = (email != nil && !email!.trimmingCharacters(in: .whitespaces).isEmpty)
        lock.lock()
        cachedHasUserLoggedIn = isPresent
        lock.unlock()
        var metadata = loadSharedMetadata() ?? ClassroomSharedMetadata()
        metadata.userEmail = email
        if isPresent {
            metadata.hasUserLoggedIn = true
        }
        saveSharedMetadata(metadata)

        for ud in allUserDefaults {
            ud.set(email, forKey: userEmailKey)
        }
    }

    public func loadUserEmail() -> String? {
        if let metaEmail = loadSharedMetadata()?.userEmail, !metaEmail.isEmpty {
            return metaEmail
        }
        for ud in allUserDefaults {
            if let email = ud.string(forKey: userEmailKey), !email.trimmingCharacters(in: .whitespaces).isEmpty {
                return email
            }
        }
        return nil
    }

    public func notifyWidgetReload() {
        #if canImport(WidgetKit)
        let isAppExtension = Bundle.main.bundleURL.pathExtension == "appex"
            || (Bundle.main.bundleIdentifier?.contains("widget") == true)
        guard !isAppExtension else { return }

        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }

    private func ensureInitialData() {
        // Cold start does not auto-populate mock data so unauthenticated users see clean login screen
    }

    public func populateMockDataManually() {
        for ud in allUserDefaults {
            ud.set(true, forKey: storageInitializedKey)
        }
        saveCourses(ClassroomStorage.mockCourses)
        saveCoursework(ClassroomStorage.mockCoursework)
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
