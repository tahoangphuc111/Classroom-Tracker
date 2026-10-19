import Foundation
import WidgetKit
import os

public final class ClassroomStorage: @unchecked Sendable {
    public static let shared = ClassroomStorage()
    public static var appGroupCandidates: [String] {
        #if os(iOS)
        return [
            "group.com.phucta.classroom",
            "VGWH8K5259.group.com.phucta.classroom",
            "4J32CASZVT.group.com.phucta.classroom"
        ]
        #else
        return [
            "VGWH8K5259.group.com.phucta.classroom",
            "4J32CASZVT.group.com.phucta.classroom",
            "group.com.phucta.classroom"
        ]
        #endif
    }

    public static var appGroupId: String {
        appGroupCandidates.first ?? "group.com.phucta.classroom"
    }

    public let allUserDefaults: [UserDefaults]

    private let userDefaults: UserDefaults
    private let coursesKey = "cached_classroom_courses"
    private let courseworkKey = "cached_classroom_coursework"
    private let coursesTimestampKey = "cached_classroom_courses_timestamp"
    private let courseworkTimestampKey = "cached_classroom_coursework_timestamp"
    private let lastSyncKey = "cached_classroom_last_sync"
    private let userEmailKey = "cached_classroom_user_email"
    private let personalNotesKey = "cached_classroom_personal_notes"
    private let personalNotesTimestampKey = "cached_classroom_personal_notes_timestamp"

    private var cachedCourses: [Course]?
    private var cachedCoursesTimestamp: Double = 0
    private var cachedCoursework: [Coursework]?
    private var cachedCourseworkTimestamp: Double = 0
    private var cachedPersonalNotes: [PersonalNote]?
    private var cachedPersonalNotesTimestamp: Double = 0
    private let lock = NSRecursiveLock()
    private let ioQueue = DispatchQueue(label: "com.phucta.classroom.storage.io", qos: .utility)
    private let storageInitializedKey = "cached_classroom_storage_initialized"
    private var lastWidgetReloadTime: TimeInterval = 0
    private var pendingWidgetReloadWorkItem: DispatchWorkItem?

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
        guard let courses = try? JSONDecoder().decode([Course].self, from: data), !courses.isEmpty else { return false }
        return courses.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
    }

    public func isMockCourseworkData(_ data: Data) -> Bool {
        guard let items = try? JSONDecoder().decode([Coursework].self, from: data), !items.isEmpty else { return false }
        return items.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
    }

    private func readDataFromDirectories(fileName: String) -> Data? {
        let logger = Logger(subsystem: "com.phucta.ClassroomTracker", category: "storage")
        var bestData: Data? = nil
        var bestDate: Date = .distantPast
        var bestIsMock: Bool = true

        for dir in allStorageDirectories {
            let fileURL = dir.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let modDate = attrs[.modificationDate] as? Date ?? .distantPast
                let data = try Data(contentsOf: fileURL)
                guard !data.isEmpty else {
                    logger.error("readData: file is 0 bytes at \(fileURL.path, privacy: .public)")
                    continue
                }

                let isMock: Bool
                if fileName == "cached_classroom_courses.json" {
                    isMock = isMockCoursesData(data)
                } else if fileName == "cached_classroom_coursework.json" {
                    isMock = isMockCourseworkData(data)
                } else {
                    isMock = false
                }

                if isAppExtension && isMock {
                    continue
                }

                logger.notice("readData found \(data.count) bytes in \(dir.path, privacy: .public), isMock=\(isMock), modDate=\(modDate)")

                if bestData == nil {
                    bestData = data
                    bestDate = modDate
                    bestIsMock = isMock
                } else if bestIsMock && !isMock {
                    bestData = data
                    bestDate = modDate
                    bestIsMock = isMock
                } else if bestIsMock == isMock && modDate > bestDate {
                    bestData = data
                    bestDate = modDate
                }
            } catch {
                logger.error("readData FAILED to read \(fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        if let bestData {
            if isAppExtension {
                if fileName == "cached_classroom_courses.json" && isMockCoursesData(bestData) {
                    return nil
                }
                if fileName == "cached_classroom_coursework.json" && isMockCourseworkData(bestData) {
                    return nil
                }
            }
        }
        return bestData
    }

    public func invalidateMemoryCache() {
        lock.lock()
        cachedCourses = nil
        cachedCoursesTimestamp = 0
        cachedCoursework = nil
        cachedCourseworkTimestamp = 0
        cachedPersonalNotes = nil
        cachedPersonalNotesTimestamp = 0
        cachedHasUserLoggedIn = nil
        lock.unlock()

        for ud in allUserDefaults {
            ud.synchronize()
        }
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
        if !isAppExtension, let cached = cachedHasUserLoggedIn {
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
        notifyWidgetReload()
    }

    private init() {
        var list: [UserDefaults] = []
        for id in ClassroomStorage.appGroupCandidates {
            if let ud = UserDefaults(suiteName: id) {
                list.append(ud)
            }
        }
        list.append(.standard)
        self.allUserDefaults = list

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
        var bestPersonalNotesData: Data?
        var bestEmail: String?
        var bestSyncTime: Double = 0
        var bestPersonalNotesTime: Double = 0

        if let fData = readDataFromDirectories(fileName: "cached_classroom_courses.json") {
            bestCoursesData = fData
        }
        if let fData = readDataFromDirectories(fileName: "cached_classroom_coursework.json") {
            bestCourseworkData = fData
        }
        if let fData = readDataFromDirectories(fileName: "cached_classroom_personal_notes.json") {
            bestPersonalNotesData = fData
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
                if let currentBest = bestCoursesData {
                    if isMockCoursesData(currentBest) && !isMockCoursesData(cData) {
                        bestCoursesData = cData
                    }
                } else {
                    bestCoursesData = cData
                }
            }
            if let cwData = ud.data(forKey: courseworkKey), !cwData.isEmpty {
                if let currentBest = bestCourseworkData {
                    if isMockCourseworkData(currentBest) && !isMockCourseworkData(cwData) {
                        bestCourseworkData = cwData
                    }
                } else {
                    bestCourseworkData = cwData
                }
            }
            let pnTime = ud.double(forKey: personalNotesTimestampKey)
            if pnTime > bestPersonalNotesTime {
                bestPersonalNotesTime = pnTime
            }
            if let pnData = ud.data(forKey: personalNotesKey), !pnData.isEmpty {
                if bestPersonalNotesData == nil {
                    bestPersonalNotesData = pnData
                } else if let currentNotes = try? JSONDecoder().decode([PersonalNote].self, from: bestPersonalNotesData!),
                          let newNotes = try? JSONDecoder().decode([PersonalNote].self, from: pnData) {
                    if currentNotes.isEmpty && !newNotes.isEmpty {
                        bestPersonalNotesData = pnData
                    }
                }
            }
            let sTime = ud.double(forKey: lastSyncKey)
            if sTime > bestSyncTime {
                bestSyncTime = sTime
            }
        }

        if bestPersonalNotesData != nil && bestPersonalNotesTime == 0 {
            bestPersonalNotesTime = Date().timeIntervalSince1970
        }

        for ud in allUserDefaults {
            if let bestCoursesData {
                ud.set(bestCoursesData, forKey: coursesKey)
            }
            if let bestCourseworkData {
                ud.set(bestCourseworkData, forKey: courseworkKey)
            }
            if let bestPersonalNotesData {
                ud.set(bestPersonalNotesData, forKey: personalNotesKey)
                if bestPersonalNotesTime > 0 {
                    ud.set(bestPersonalNotesTime, forKey: personalNotesTimestampKey)
                }
            }
            if let bestEmail {
                ud.set(bestEmail, forKey: userEmailKey)
            }
            if bestSyncTime > 0 {
                ud.set(bestSyncTime, forKey: lastSyncKey)
            }
            ud.synchronize()
        }

        if let bestCoursesData {
            writeDataToAllDirectories(bestCoursesData, fileName: "cached_classroom_courses.json")
        }
        if let bestCourseworkData {
            writeDataToAllDirectories(bestCourseworkData, fileName: "cached_classroom_coursework.json")
        }
        if let bestPersonalNotesData {
            writeDataToAllDirectories(bestPersonalNotesData, fileName: "cached_classroom_personal_notes.json")
        }

        let isUserLogged = !(bestEmail?.isEmpty ?? true) || hasUserLoggedIn
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

    private func getLatestUserDefaultsTimestamp(forKey key: String) -> Double {
        var maxTime: Double = 0
        for ud in allUserDefaults {
            let t = ud.double(forKey: key)
            if t > maxTime { maxTime = t }
        }
        return maxTime
    }

    public func loadCourses() -> [Course] {
        lock.lock()
        let memoryCached = cachedCourses
        let memoryTimestamp = cachedCoursesTimestamp
        lock.unlock()

        if !isAppExtension, let memoryCached, memoryTimestamp > 0 {
            let primaryTime = userDefaults.double(forKey: coursesTimestampKey)
            if primaryTime <= memoryTimestamp {
                return memoryCached
            }
            let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: coursesTimestampKey)
            if memoryTimestamp >= latestTimestamp {
                return memoryCached
            }
        }

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: coursesTimestampKey)

        var loaded: [Course]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_courses.json") {
            loaded = try? JSONDecoder().decode([Course].self, from: data)
        }
        for ud in allUserDefaults {
            if let data = ud.data(forKey: coursesKey),
               let decoded = try? JSONDecoder().decode([Course].self, from: data),
               !decoded.isEmpty {
                let currentIsMock = loaded.map { items in !items.isEmpty && items.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil } } ?? true
                let newIsMock = !decoded.isEmpty && decoded.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
                if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                    loaded = decoded
                }
            }
        }

        // Never show mock data in widget extensions
        if isAppExtension, let loadedItems = loaded {
            let allMock = !loadedItems.isEmpty && loadedItems.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
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

        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let encoded = try? JSONEncoder().encode(items) else { return }

            self.writeDataToAllDirectories(encoded, fileName: "cached_classroom_coursework.json")

            for ud in self.allUserDefaults {
                ud.set(encoded, forKey: self.courseworkKey)
                ud.set(timestamp, forKey: self.courseworkTimestampKey)
            }

            self.notifyWidgetReload()
        }
    }

    public func loadCoursework() -> [Coursework] {
        lock.lock()
        let memoryCached = cachedCoursework
        let memoryTimestamp = cachedCourseworkTimestamp
        lock.unlock()

        if !isAppExtension, let memoryCached, memoryTimestamp > 0 {
            let primaryTime = userDefaults.double(forKey: courseworkTimestampKey)
            if primaryTime <= memoryTimestamp {
                return memoryCached
            }
            let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: courseworkTimestampKey)
            if memoryTimestamp >= latestTimestamp {
                return memoryCached
            }
        }

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: courseworkTimestampKey)

        var loaded: [Coursework]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_coursework.json") {
            loaded = try? JSONDecoder().decode([Coursework].self, from: data)
        }
        for ud in allUserDefaults {
            if let data = ud.data(forKey: courseworkKey),
               let decoded = try? JSONDecoder().decode([Coursework].self, from: data),
               !decoded.isEmpty {
                let currentIsMock = loaded.map { items in !items.isEmpty && items.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil } } ?? true
                let newIsMock = !decoded.isEmpty && decoded.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
                if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                    loaded = decoded
                }
            }
        }

        // Never show mock data in widget extensions
        if isAppExtension, let loadedItems = loaded {
            let allMock = !loadedItems.isEmpty && loadedItems.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
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

    public func filterItemsByActiveCourses(_ items: [Coursework], courses: [Course]? = nil) -> [Coursework] {
        let loadedCourses = courses ?? loadCourses()
        guard !loadedCourses.isEmpty, !items.isEmpty else { return items }

        var hasUnselected = false
        var allCourseIds = Set<String>()
        var activeCourseIds = Set<String>()
        for course in loadedCourses {
            allCourseIds.insert(course.id)
            if course.isSelectedForWidget {
                activeCourseIds.insert(course.id)
            } else {
                hasUnselected = true
            }
        }

        if !hasUnselected || activeCourseIds.isEmpty { return items }

        var result: [Coursework] = []
        var anyMatchesLoadedCourses = false
        for item in items {
            if allCourseIds.contains(item.courseId) {
                anyMatchesLoadedCourses = true
                if activeCourseIds.contains(item.courseId) {
                    result.append(item)
                }
            } else {
                result.append(item)
            }
        }

        return anyMatchesLoadedCourses ? result : items
    }

    public func sortCoursework(_ items: [Coursework]) -> [Coursework] {
        items.sorted { (first, second) -> Bool in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            switch (first.dueDate, second.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 < d2 }
                let titleOrder = first.title.localizedStandardCompare(second.title)
                if titleOrder != .orderedSame {
                    return titleOrder == .orderedAscending
                }
                return first.id < second.id
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                let titleOrder = first.title.localizedStandardCompare(second.title)
                if titleOrder != .orderedSame {
                    return titleOrder == .orderedAscending
                }
                return first.id < second.id
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
                    let titleOrder = first.title.localizedStandardCompare(second.title)
                    if titleOrder != .orderedSame {
                        return titleOrder == .orderedAscending
                    }
                    return first.id < second.id
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    let titleOrder = first.title.localizedStandardCompare(second.title)
                    if titleOrder != .orderedSame {
                        return titleOrder == .orderedAscending
                    }
                    return first.id < second.id
                }
            }
    }

    public func getTodayAndTomorrowCoursework(includeCompleted: Bool = true) -> [Coursework] {
        let allItems = loadCoursework()
        let relevant = filterItemsByActiveCourses(allItems)
        let calendar = Calendar.autoupdatingCurrent
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

    public func getTomorrowCoursework(items: [Coursework]? = nil, courses: [Course]? = nil, includeCompleted: Bool = true, includeNotes: Bool = true) -> [Coursework] {
        let allItems = items ?? loadCoursework()
        let relevant = filterItemsByActiveCourses(allItems, courses: courses)
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        var tomorrowFiltered: [Coursework] = []
        var todayIncomplete: [Coursework] = []
        var laterUpcoming: [Coursework] = []
        var undated: [Coursework] = []

        for item in relevant {
            let isEligible = includeCompleted ? true : !item.isCompleted
            guard let dueDate = item.dueDate else {
                if isEligible { undated.append(item) }
                continue
            }

            // Triết lý: Cứ hết hạn thì tính là đã hoàn thành.
            // Các bài tập đã qua hạn (dueDate < now) không còn là bài tập cần giải quyết và không được đưa vào danh sách nhắc nhở widget.
            if dueDate >= startOfTomorrow && dueDate < startOfDayAfter {
                if isEligible { tomorrowFiltered.append(item) }
            } else if !item.isCompleted {
                if dueDate >= now && dueDate < startOfTomorrow {
                    todayIncomplete.append(item)
                } else if isEligible && dueDate >= startOfDayAfter {
                    laterUpcoming.append(item)
                }
            } else if isEligible && dueDate >= startOfDayAfter {
                laterUpcoming.append(item)
            }
        }

        if includeNotes {
            let tomorrowNotes = getTomorrowPersonalNotes(includeCompleted: includeCompleted)
            for note in tomorrowNotes {
                if note.courseworkId == nil {
                    let noteCoursework = Coursework(
                        id: "note_\(note.id)",
                        courseId: note.courseId ?? "personal_note",
                        courseName: note.courseName ?? "Ghi chú",
                        title: note.title,
                        description: note.content,
                        dueDate: note.dueDate,
                        status: note.isCompleted ? .turnedIn : .pending,
                        isManuallyCompleted: note.isCompleted
                    )
                    tomorrowFiltered.append(noteCoursework)
                }
            }
        }

        if !tomorrowFiltered.isEmpty { return sortCoursework(tomorrowFiltered) }
        if !todayIncomplete.isEmpty { return sortCoursework(todayIncomplete) }
        if !laterUpcoming.isEmpty { return sortCoursework(laterUpcoming) }
        if !undated.isEmpty { return sortCoursework(undated) }

        return []
    }

    public func clearAllData(includePersonalNotes: Bool = true) {
        lock.lock()
        cachedCourses = nil
        cachedCoursesTimestamp = 0
        cachedCoursework = nil
        cachedCourseworkTimestamp = 0
        if includePersonalNotes {
            cachedPersonalNotes = nil
            cachedPersonalNotesTimestamp = 0
        }
        cachedHasUserLoggedIn = nil
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            for dir in self.allStorageDirectories {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_courses.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_coursework.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_metadata.json"))
                if includePersonalNotes {
                    try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_personal_notes.json"))
                }
            }

            for ud in self.allUserDefaults {
                ud.removeObject(forKey: self.coursesKey)
                ud.removeObject(forKey: self.courseworkKey)
                ud.removeObject(forKey: self.coursesTimestampKey)
                ud.removeObject(forKey: self.courseworkTimestampKey)
                ud.removeObject(forKey: self.lastSyncKey)
                ud.removeObject(forKey: self.userEmailKey)
                if includePersonalNotes {
                    ud.removeObject(forKey: self.personalNotesKey)
                    ud.removeObject(forKey: self.personalNotesTimestampKey)
                }
                ud.synchronize()
            }

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
        let isPresent = !(email?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        lock.lock()
        cachedHasUserLoggedIn = isPresent
        lock.unlock()
        var metadata = loadSharedMetadata() ?? ClassroomSharedMetadata()
        metadata.userEmail = email
        metadata.hasUserLoggedIn = isPresent
        saveSharedMetadata(metadata)

        for ud in allUserDefaults {
            if let email {
                ud.set(email, forKey: userEmailKey)
            } else {
                ud.removeObject(forKey: userEmailKey)
            }
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

        lock.lock()
        pendingWidgetReloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            for ud in self.allUserDefaults {
                ud.synchronize()
            }
            #if os(macOS)
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name("com.phucta.ClassroomTracker.widgetReload"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            #endif
            WidgetCenter.shared.reloadAllTimelines()
        }
        pendingWidgetReloadWorkItem = workItem

        let now = Date().timeIntervalSince1970
        let timeSinceLast = now - lastWidgetReloadTime
        if timeSinceLast >= 1.0 {
            lastWidgetReloadTime = now
            lock.unlock()
            DispatchQueue.main.async(execute: workItem)
        } else {
            lock.unlock()
            let delay = max(0.1, 1.0 - timeSinceLast)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
        let calendar = Calendar.autoupdatingCurrent
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

    // MARK: - Personal Notes Storage

    public func savePersonalNotes(_ notes: [PersonalNote]) {
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedPersonalNotes = notes
        cachedPersonalNotesTimestamp = timestamp
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let encoded = try? JSONEncoder().encode(notes) else { return }

            self.writeDataToAllDirectories(encoded, fileName: "cached_classroom_personal_notes.json")

            for ud in self.allUserDefaults {
                ud.set(encoded, forKey: self.personalNotesKey)
                ud.set(timestamp, forKey: self.personalNotesTimestampKey)
            }

            self.notifyWidgetReload()
        }
    }

    public func loadPersonalNotes() -> [PersonalNote] {
        lock.lock()
        let memoryCached = cachedPersonalNotes
        let memoryTimestamp = cachedPersonalNotesTimestamp
        lock.unlock()

        if !isAppExtension, let memoryCached, memoryTimestamp > 0 {
            let primaryTime = userDefaults.double(forKey: personalNotesTimestampKey)
            if primaryTime <= memoryTimestamp {
                return memoryCached
            }
            let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: personalNotesTimestampKey)
            if memoryTimestamp >= latestTimestamp {
                return memoryCached
            }
        }

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: personalNotesTimestampKey)

        var loaded: [PersonalNote]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_personal_notes.json") {
            loaded = try? JSONDecoder().decode([PersonalNote].self, from: data)
        }
        for ud in allUserDefaults {
            if let data = ud.data(forKey: personalNotesKey),
               let decoded = try? JSONDecoder().decode([PersonalNote].self, from: data),
               !decoded.isEmpty {
                if loaded == nil || loaded?.isEmpty == true {
                    loaded = decoded
                }
            }
        }

        let result = loaded ?? []
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        cachedPersonalNotes = result
        cachedPersonalNotesTimestamp = effectiveTimestamp
        lock.unlock()

        return result
    }

    public func getNoteForCoursework(courseworkId: String) -> PersonalNote? {
        let allNotes = loadPersonalNotes()
        return allNotes.first { $0.courseworkId == courseworkId }
    }

    public func saveNoteForCoursework(
        courseworkId: String,
        courseId: String? = nil,
        courseName: String? = nil,
        title: String,
        content: String
    ) {
        var allNotes = loadPersonalNotes()
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = allNotes.firstIndex(where: { $0.courseworkId == courseworkId }) {
            if trimmed.isEmpty {
                allNotes.remove(at: index)
            } else {
                allNotes[index].content = trimmed
                allNotes[index].updatedAt = Date()
                if let courseId { allNotes[index].courseId = courseId }
                if let courseName { allNotes[index].courseName = courseName }
            }
        } else if !trimmed.isEmpty {
            let newNote = PersonalNote(
                courseworkId: courseworkId,
                courseId: courseId,
                courseName: courseName,
                title: title,
                content: trimmed
            )
            allNotes.append(newNote)
        }
        savePersonalNotes(allNotes)
    }

    public func deletePersonalNote(id: String) {
        var allNotes = loadPersonalNotes()
        allNotes.removeAll { $0.id == id }
        savePersonalNotes(allNotes)
    }

    public func togglePersonalNoteCompletion(id: String) {
        var allNotes = loadPersonalNotes()
        if let index = allNotes.firstIndex(where: { $0.id == id }) {
            allNotes[index].isCompleted.toggle()
            allNotes[index].updatedAt = Date()
            savePersonalNotes(allNotes)
        }
    }

    public func getTomorrowPersonalNotes(notes: [PersonalNote]? = nil, includeCompleted: Bool = false) -> [PersonalNote] {
        let allNotes = notes ?? loadPersonalNotes()
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        return allNotes.filter { note in
            if !includeCompleted && note.isCompleted {
                return false
            }
            guard let dueDate = note.dueDate else { return false }
            return dueDate >= startOfTomorrow && dueDate < startOfDayAfter
        }
    }
}
