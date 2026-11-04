import Foundation
import WidgetKit
import os

public final class ClassroomStorage: @unchecked Sendable {
    public static let shared = ClassroomStorage()
    public static let appGroupCandidates: [String] = {
        return [
            "group.com.phucta.classroom",
            "4J32CASZVT.group.com.phucta.classroom",
            "VGWH8K5259.group.com.phucta.classroom"
        ]
    }()

    public static var appGroupId: String {
        appGroupCandidates.first ?? "group.com.phucta.classroom"
    }

    public let allUserDefaults: [UserDefaults]

    public static let tokenUserDefaultsKey = "secure_oauth_tokens_cache"
    private let userDefaults: UserDefaults
    private let userLoggedInKey = "cached_classroom_user_logged_in"
    private let coursesKey = "cached_classroom_courses"
    private let courseworkKey = "cached_classroom_coursework"
    private let coursesTimestampKey = "cached_classroom_courses_timestamp"
    private let courseworkTimestampKey = "cached_classroom_coursework_timestamp"
    private let lastSyncKey = "cached_classroom_last_sync"
    private let userEmailKey = "cached_classroom_user_email"
    private let personalNotesKey = "cached_classroom_personal_notes"
    private let personalNotesTimestampKey = "cached_classroom_personal_notes_timestamp"

    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()

    private var cachedCourses: [Course]?
    private var cachedCoursesTimestamp: Double = 0
    private var cachedCoursework: [Coursework]?
    private var cachedCourseworkTimestamp: Double = 0
    private var cachedPersonalNotes: [PersonalNote]?
    private var cachedPersonalNotesTimestamp: Double = 0
    private var cachedMetadata: ClassroomSharedMetadata?
    private let lock = NSRecursiveLock()
    private let ioQueue = DispatchQueue(label: "com.phucta.classroom.storage.io", qos: .utility)
    private static let ioQueueKey = DispatchSpecificKey<Void>()
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

    public static let sharedStorageDirectories: [URL] = {
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
        return dirs
    }()

    private static var inaccessibleDirectoryPaths: Set<String> = []
    private static let directoryLock = NSLock()

    private var allStorageDirectories: [URL] {
        Self.sharedStorageDirectories
    }

    private func writeDataToAllDirectories(_ data: Data, fileName: String) {
        let logger = Logger(subsystem: "com.phucta.ClassroomTracker", category: "storage")
        for dir in allStorageDirectories {
            Self.directoryLock.lock()
            let isInaccessible = Self.inaccessibleDirectoryPaths.contains(dir.path)
            Self.directoryLock.unlock()
            if isInaccessible { continue }

            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let fileURL = dir.appendingPathComponent(fileName)
                let coordinator = NSFileCoordinator(filePresenter: nil)
                var coordError: NSError?
                var writeSuccess = false

                coordinator.coordinate(writingItemAt: fileURL, options: [], error: &coordError) { targetURL in
                    do {
                        try data.write(to: targetURL, options: .atomic)
                        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: targetURL.path)
                        writeSuccess = true
                    } catch {
                        if (try? data.write(to: targetURL, options: [])) != nil {
                            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: targetURL.path)
                            writeSuccess = true
                        }
                    }
                }

                if !writeSuccess && coordError != nil {
                    do {
                        try data.write(to: fileURL, options: .atomic)
                        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
                    } catch {
                        try data.write(to: fileURL, options: [])
                        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
                    }
                }
                logger.notice("WROTE \(data.count) bytes of \(fileName, privacy: .public)")
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && (nsError.code == NSFileWriteNoPermissionError || nsError.code == 513) {
                    Self.directoryLock.lock()
                    Self.inaccessibleDirectoryPaths.insert(dir.path)
                    Self.directoryLock.unlock()
                }
                logger.error("Error writing \(fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public var isAppExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
            || (Bundle.main.bundleIdentifier?.contains("widget") == true)
    }

    public static func isMockCourses(_ courses: [Course]) -> Bool {
        guard !courses.isEmpty else { return false }
        return courses.allSatisfy { $0.id.hasPrefix("c") && Int($0.id.dropFirst(1)) != nil }
    }

    public static func isMockCoursework(_ items: [Coursework]) -> Bool {
        guard !items.isEmpty else { return false }
        return items.allSatisfy { $0.id.hasPrefix("cw") && Int($0.id.dropFirst(2)) != nil }
    }

    public func isMockCoursesData(_ data: Data) -> Bool {
        let prefixLimit = min(data.count, 256)
        if prefixLimit > 20, let sample = String(data: data.prefix(prefixLimit), encoding: .utf8) {
            if sample.contains("\"id\":\"c") || sample.contains("\"id\": \"c") {
                if let courses = try? Self.jsonDecoder.decode([Course].self, from: data) {
                    return Self.isMockCourses(courses)
                }
            } else if sample.contains("\"id\":\"") {
                return false
            }
        }
        guard let courses = try? Self.jsonDecoder.decode([Course].self, from: data) else { return false }
        return Self.isMockCourses(courses)
    }

    public func isMockCourseworkData(_ data: Data) -> Bool {
        let prefixLimit = min(data.count, 256)
        if prefixLimit > 20, let sample = String(data: data.prefix(prefixLimit), encoding: .utf8) {
            if sample.contains("\"id\":\"cw") || sample.contains("\"id\": \"cw") {
                if let items = try? Self.jsonDecoder.decode([Coursework].self, from: data) {
                    return Self.isMockCoursework(items)
                }
            } else if sample.contains("\"id\":\"") {
                return false
            }
        }
        guard let items = try? Self.jsonDecoder.decode([Coursework].self, from: data) else { return false }
        return Self.isMockCoursework(items)
    }

    private func readDataFromDirectories(fileName: String) -> Data? {
        let logger = Logger(subsystem: "com.phucta.ClassroomTracker", category: "storage")
        var bestData: Data? = nil
        var bestDate: Date = .distantPast
        var bestIsMock: Bool = true

        for dir in allStorageDirectories {
            Self.directoryLock.lock()
            let isInaccessible = Self.inaccessibleDirectoryPaths.contains(dir.path)
            Self.directoryLock.unlock()
            if isInaccessible { continue }

            let fileURL = dir.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let modDate = attrs[.modificationDate] as? Date ?? .distantPast

                let coordinator = NSFileCoordinator(filePresenter: nil)
                var coordError: NSError?
                var readData: Data?

                coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordError) { targetURL in
                    readData = try? Data(contentsOf: targetURL)
                }

                let data = readData ?? (try? Data(contentsOf: fileURL)) ?? Data()
                guard !data.isEmpty else {
                    logger.error("readData: file is 0 bytes or unreadable for \(fileName, privacy: .public)")
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

                logger.notice("readData found \(data.count) bytes of \(fileName, privacy: .public), isMock=\(isMock), modDate=\(modDate)")

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
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && (nsError.code == NSFileReadNoPermissionError || nsError.code == 257) {
                    Self.directoryLock.lock()
                    Self.inaccessibleDirectoryPaths.insert(dir.path)
                    Self.directoryLock.unlock()
                }
                logger.error("readData FAILED for \(fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        return bestData
    }

    public func flushIOQueue() {
        if DispatchQueue.getSpecific(key: Self.ioQueueKey) == nil {
            ioQueue.sync { }
        }
    }

    public func invalidateMemoryCache() {
        if DispatchQueue.getSpecific(key: Self.ioQueueKey) == nil {
            ioQueue.sync { }
        }
        lock.lock()
        cachedCourses = nil
        cachedCoursesTimestamp = 0
        cachedCoursework = nil
        cachedCourseworkTimestamp = 0
        cachedPersonalNotes = nil
        cachedPersonalNotesTimestamp = 0
        cachedHasUserLoggedIn = nil
        cachedMetadata = nil
        lock.unlock()

        for ud in allUserDefaults {
            ud.synchronize()
        }
    }

    public func loadSharedMetadata() -> ClassroomSharedMetadata? {
        lock.lock()
        if !isAppExtension, let cached = cachedMetadata {
            lock.unlock()
            return cached
        }
        lock.unlock()

        if let data = readDataFromDirectories(fileName: "cached_classroom_metadata.json"),
           let metadata = try? Self.jsonDecoder.decode(ClassroomSharedMetadata.self, from: data) {
            lock.lock()
            cachedMetadata = metadata
            lock.unlock()
            return metadata
        }
        return nil
    }

    public func saveSharedMetadata(_ metadata: ClassroomSharedMetadata) {
        lock.lock()
        cachedMetadata = metadata
        if metadata.hasUserLoggedIn || (metadata.userEmail != nil && !(metadata.userEmail?.isEmpty ?? true)) {
            cachedHasUserLoggedIn = true
        }
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            if let data = try? Self.jsonEncoder.encode(metadata) {
                self.writeDataToAllDirectories(data, fileName: "cached_classroom_metadata.json")
            }
        }
    }

    private var cachedHasUserLoggedIn: Bool? = nil

    public var hasUserLoggedIn: Bool {
        lock.lock()
        if !isAppExtension, let cached = cachedHasUserLoggedIn {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // 1. Direct App Group UserDefaults flag check
        for ud in allUserDefaults {
            if ud.bool(forKey: userLoggedInKey) {
                lock.lock()
                cachedHasUserLoggedIn = true
                lock.unlock()
                return true
            }
        }

        // 2. Token cache existence in App Group UserDefaults
        for ud in allUserDefaults {
            if let data = ud.data(forKey: Self.tokenUserDefaultsKey), !data.isEmpty {
                lock.lock()
                cachedHasUserLoggedIn = true
                lock.unlock()
                return true
            }
        }

        // 3. Shared metadata file check
        if let metadata = loadSharedMetadata(), metadata.hasUserLoggedIn {
            lock.lock()
            cachedHasUserLoggedIn = true
            lock.unlock()
            return true
        }

        // 4. Stored user email check
        if let email = loadUserEmail(), !email.trimmingCharacters(in: .whitespaces).isEmpty {
            lock.lock()
            cachedHasUserLoggedIn = true
            lock.unlock()
            return true
        }

        // 5. Non-mock courses existence check
        let courses = loadCourses()
        if !courses.isEmpty && !Self.isMockCourses(courses) {
            lock.lock()
            cachedHasUserLoggedIn = true
            lock.unlock()
            return true
        }

        // 6. Non-mock coursework existence check
        let items = loadCoursework()
        if !items.isEmpty && !Self.isMockCoursework(items) {
            lock.lock()
            cachedHasUserLoggedIn = true
            lock.unlock()
            return true
        }

        // 7. Token file existence check in storage directories
        for dir in allStorageDirectories {
            let tokenFile = dir.appendingPathComponent("cached_oauth_tokens.json")
            if FileManager.default.fileExists(atPath: tokenFile.path) {
                lock.lock()
                cachedHasUserLoggedIn = true
                lock.unlock()
                return true
            }
        }

        lock.lock()
        cachedHasUserLoggedIn = false
        lock.unlock()
        return false
    }

    public func saveUserLoggedIn(_ loggedIn: Bool) {
        lock.lock()
        cachedHasUserLoggedIn = loggedIn
        var metadata = cachedMetadata ?? ClassroomSharedMetadata()
        metadata.hasUserLoggedIn = loggedIn
        cachedMetadata = metadata
        lock.unlock()

        for ud in allUserDefaults {
            ud.set(loggedIn, forKey: userLoggedInKey)
            if !loggedIn {
                ud.removeObject(forKey: Self.tokenUserDefaultsKey)
            }
            ud.synchronize()
        }

        ioQueue.async { [weak self] in
            guard let self else { return }
            if let data = try? Self.jsonEncoder.encode(metadata) {
                self.writeDataToAllDirectories(data, fileName: "cached_classroom_metadata.json")
            }
            self.notifyWidgetReload()
        }
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

        self.ioQueue.setSpecific(key: Self.ioQueueKey, value: ())

        if !isAppExtension {
            ioQueue.async { [weak self] in
                self?.synchronizeAllStorageLayers()
                self?.ensureInitialData()
            }
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
                } else if let currentNotes = try? Self.jsonDecoder.decode([PersonalNote].self, from: bestPersonalNotesData!),
                          let newNotes = try? Self.jsonDecoder.decode([PersonalNote].self, from: pnData) {
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
        if let metaData = try? Self.jsonEncoder.encode(metadata) {
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
            guard let encoded = try? Self.jsonEncoder.encode(courses) else { return }

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

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: coursesTimestampKey)
        if !isAppExtension, let memoryCached, memoryTimestamp > 0, memoryTimestamp >= latestTimestamp {
            return memoryCached
        }

        var loaded: [Course]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_courses.json") {
            loaded = try? Self.jsonDecoder.decode([Course].self, from: data)
        }
        let currentIsMock = loaded.map { Self.isMockCourses($0) } ?? true
        if loaded == nil || loaded?.isEmpty == true || currentIsMock {
            for ud in allUserDefaults {
                if let data = ud.data(forKey: coursesKey),
                   let decoded = try? Self.jsonDecoder.decode([Course].self, from: data),
                   !decoded.isEmpty {
                    let newIsMock = Self.isMockCourses(decoded)
                    if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                        loaded = decoded
                        if !newIsMock { break }
                    }
                }
            }
        }

        if isAppExtension, let loadedItems = loaded, Self.isMockCourses(loadedItems) {
            loaded = nil
        }

        let result: [Course] = loaded ?? []
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        if cachedCourses == nil || cachedCoursesTimestamp <= effectiveTimestamp {
            cachedCourses = result
            cachedCoursesTimestamp = effectiveTimestamp
            lock.unlock()
            return result
        } else {
            let existing = cachedCourses ?? result
            lock.unlock()
            return existing
        }
    }

    public func saveCoursework(_ items: [Coursework]) {
        let timestamp = Date().timeIntervalSince1970
        lock.lock()
        cachedCoursework = items
        cachedCourseworkTimestamp = timestamp
        lock.unlock()

        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let encoded = try? Self.jsonEncoder.encode(items) else { return }

            self.writeDataToAllDirectories(encoded, fileName: "cached_classroom_coursework.json")

            let cutoff = Date().addingTimeInterval(-48 * 3600)
            let widgetItems = items.filter { item in
                if !item.isCompleted { return true }
                if let due = item.dueDate { return due >= cutoff }
                return false
            }
            if let encodedWidget = try? Self.jsonEncoder.encode(widgetItems) {
                self.writeDataToAllDirectories(encodedWidget, fileName: "cached_classroom_widget_coursework.json")
            }

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

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: courseworkTimestampKey)
        if !isAppExtension, let memoryCached, memoryTimestamp > 0, memoryTimestamp >= latestTimestamp {
            return memoryCached
        }

        var loaded: [Coursework]?
        if isAppExtension, let data = readDataFromDirectories(fileName: "cached_classroom_widget_coursework.json") {
            loaded = try? Self.jsonDecoder.decode([Coursework].self, from: data)
        }
        if loaded == nil || loaded?.isEmpty == true {
            if let data = readDataFromDirectories(fileName: "cached_classroom_coursework.json") {
                loaded = try? Self.jsonDecoder.decode([Coursework].self, from: data)
            }
        }
        let currentIsMock = loaded.map { Self.isMockCoursework($0) } ?? true
        if loaded == nil || loaded?.isEmpty == true || currentIsMock {
            for ud in allUserDefaults {
                if let data = ud.data(forKey: courseworkKey),
                   let decoded = try? Self.jsonDecoder.decode([Coursework].self, from: data),
                   !decoded.isEmpty {
                    let newIsMock = Self.isMockCoursework(decoded)
                    if loaded == nil || loaded?.isEmpty == true || (currentIsMock && !newIsMock) {
                        loaded = decoded
                        if !newIsMock { break }
                    }
                }
            }
        }

        if isAppExtension, let loadedItems = loaded, Self.isMockCoursework(loadedItems) {
            loaded = nil
        }

        let result: [Coursework] = loaded ?? []
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        if cachedCoursework == nil || cachedCourseworkTimestamp <= effectiveTimestamp {
            cachedCoursework = result
            cachedCourseworkTimestamp = effectiveTimestamp
            lock.unlock()
            return result
        } else {
            let existing = cachedCoursework ?? result
            lock.unlock()
            return existing
        }
    }

    public func filterItemsByActiveCourses(_ items: [Coursework], courses: [Course]? = nil) -> [Coursework] {
        let loadedCourses = courses ?? loadCourses()
        guard !loadedCourses.isEmpty, !items.isEmpty else { return items }

        var hasUnselected = false
        var allCourseIds = Set<String>(minimumCapacity: loadedCourses.count)
        var activeCourseIds = Set<String>(minimumCapacity: loadedCourses.count)
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
        result.reserveCapacity(items.count)
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
        let calendar = ClassroomDateFormatters.gregorianCalendar
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
        let calendar = ClassroomDateFormatters.gregorianCalendar
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return []
        }

        var tomorrowFiltered: [Coursework] = []
        var todayIncompleteFiltered: [Coursework] = []
        var todayCompletedFiltered: [Coursework] = []
        var laterUpcoming: [Coursework] = []
        var undated: [Coursework] = []

        for item in relevant {
            let isEligible = includeCompleted ? true : !item.isCompleted
            guard let dueDate = item.dueDate else {
                if isEligible { undated.append(item) }
                continue
            }

            if dueDate >= startOfTomorrow && dueDate < startOfDayAfter {
                if isEligible { tomorrowFiltered.append(item) }
            } else if dueDate >= now && dueDate < startOfTomorrow {
                if item.isCompleted {
                    if includeCompleted { todayCompletedFiltered.append(item) }
                } else {
                    todayIncompleteFiltered.append(item)
                }
            } else if dueDate >= startOfDayAfter {
                if isEligible { laterUpcoming.append(item) }
            }
        }

        if includeNotes {
            let tomorrowNotes = getTomorrowPersonalNotes(includeCompleted: includeCompleted)
            let courseList = courses ?? loadCourses()
            let activeCourseIds = Set(courseList.filter(\.isSelectedForWidget).map(\.id))
            let allCourseIds = Set(courseList.map(\.id))
            let isFilterActive = !activeCourseIds.isEmpty && activeCourseIds.count < allCourseIds.count

            for note in tomorrowNotes {
                if note.courseworkId == nil {
                    if isFilterActive, let cid = note.courseId, allCourseIds.contains(cid), !activeCourseIds.contains(cid) {
                        continue
                    }
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
        if !todayIncompleteFiltered.isEmpty { return sortCoursework(todayIncompleteFiltered) }
        if !laterUpcoming.isEmpty { return sortCoursework(laterUpcoming) }
        if !undated.isEmpty { return sortCoursework(undated) }
        if !todayCompletedFiltered.isEmpty { return sortCoursework(todayCompletedFiltered) }

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
        cachedHasUserLoggedIn = false
        cachedMetadata = ClassroomSharedMetadata(hasUserLoggedIn: false)
        lock.unlock()

        for ud in self.allUserDefaults {
            ud.set(false, forKey: self.userLoggedInKey)
            ud.removeObject(forKey: Self.tokenUserDefaultsKey)
            ud.removeObject(forKey: self.userEmailKey)
            ud.synchronize()
        }

        let performDiskClean = {
            for dir in self.allStorageDirectories {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_courses.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_coursework.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_widget_coursework.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_classroom_metadata.json"))
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("cached_oauth_tokens.json"))
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
                ud.removeObject(forKey: self.userLoggedInKey)
                ud.removeObject(forKey: Self.tokenUserDefaultsKey)
                if includePersonalNotes {
                    ud.removeObject(forKey: self.personalNotesKey)
                    ud.removeObject(forKey: self.personalNotesTimestampKey)
                }
                ud.synchronize()
            }

            self.notifyWidgetReload()
        }

        if DispatchQueue.getSpecific(key: Self.ioQueueKey) != nil {
            performDiskClean()
        } else {
            ioQueue.sync(execute: performDiskClean)
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
                if newStatus == .turnedIn || newStatus == .returned {
                    currentItems[i].isManuallyCompleted = true
                } else if newStatus == .pending {
                    currentItems[i].isManuallyCompleted = false
                }
                changed = true
            }
        }
        if changed {
            saveCoursework(currentItems)
        }
    }

    public func toggleCourseworkCompletion(id: String, completed: Bool? = nil) {
        lock.lock()
        defer { lock.unlock() }

        var currentItems = loadCoursework()
        guard let index = currentItems.firstIndex(where: { $0.id == id }) else { return }
        let newStatus = completed ?? !currentItems[index].isCompleted
        currentItems[index].isManuallyCompleted = newStatus
        currentItems[index].status = newStatus ? .turnedIn : .pending
        saveCoursework(currentItems)
    }

    public func reconcileCoursework(incoming: [Coursework]) -> [Coursework] {
        let cached = loadCoursework()
        var cachedMap: [String: Coursework] = [:]
        cachedMap.reserveCapacity(cached.count)
        for item in cached {
            cachedMap[item.id] = item
        }
        return incoming.map { item in
            guard let fresh = cachedMap[item.id] else { return item }
            var updated = item
            let localIsManuallyCompleted = fresh.isManuallyCompleted
            let incomingIsPendingOrLate = item.status == .pending || item.status == .late
            let shouldPreserveLocalStatus = incomingIsPendingOrLate && localIsManuallyCompleted

            if shouldPreserveLocalStatus {
                updated.status = fresh.status == .returned ? .returned : .turnedIn
            } else {
                updated.status = item.status
            }

            if item.status == .turnedIn || item.status == .returned {
                updated.isManuallyCompleted = false
            } else {
                updated.isManuallyCompleted = localIsManuallyCompleted || item.isManuallyCompleted
            }
            return updated
        }
    }

    public func saveLastSyncTime(_ date: Date) {
        let timestamp = date.timeIntervalSince1970
        lock.lock()
        var metadata = cachedMetadata ?? ClassroomSharedMetadata()
        metadata.lastSyncTimestamp = timestamp
        cachedMetadata = metadata
        lock.unlock()

        for ud in allUserDefaults {
            ud.set(timestamp, forKey: lastSyncKey)
        }

        ioQueue.async { [weak self] in
            guard let self else { return }
            if let data = try? Self.jsonEncoder.encode(metadata) {
                self.writeDataToAllDirectories(data, fileName: "cached_classroom_metadata.json")
            }
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
        var metadata = cachedMetadata ?? ClassroomSharedMetadata()
        metadata.userEmail = email
        metadata.hasUserLoggedIn = isPresent
        cachedMetadata = metadata
        lock.unlock()

        for ud in allUserDefaults {
            if let email {
                ud.set(email, forKey: userEmailKey)
                ud.set(true, forKey: userLoggedInKey)
            } else {
                ud.removeObject(forKey: userEmailKey)
            }
            ud.synchronize()
        }

        ioQueue.async { [weak self] in
            guard let self else { return }
            if let data = try? Self.jsonEncoder.encode(metadata) {
                self.writeDataToAllDirectories(data, fileName: "cached_classroom_metadata.json")
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
            self.lock.lock()
            self.lastWidgetReloadTime = Date().timeIntervalSince1970
            self.lock.unlock()
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
        let calendar = ClassroomDateFormatters.gregorianCalendar
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
            guard let encoded = try? Self.jsonEncoder.encode(notes) else { return }

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

        let latestTimestamp = getLatestUserDefaultsTimestamp(forKey: personalNotesTimestampKey)
        if !isAppExtension, let memoryCached, memoryTimestamp > 0, memoryTimestamp >= latestTimestamp {
            return memoryCached
        }

        var loaded: [PersonalNote]?
        if let data = readDataFromDirectories(fileName: "cached_classroom_personal_notes.json") {
            loaded = try? Self.jsonDecoder.decode([PersonalNote].self, from: data)
        }
        if loaded == nil || loaded?.isEmpty == true {
            for ud in allUserDefaults {
                if let data = ud.data(forKey: personalNotesKey),
                   let decoded = try? Self.jsonDecoder.decode([PersonalNote].self, from: data),
                   !decoded.isEmpty {
                    loaded = decoded
                    break
                }
            }
        }

        let result = loaded ?? []
        let effectiveTimestamp = latestTimestamp > 0 ? latestTimestamp : Date().timeIntervalSince1970

        lock.lock()
        if cachedPersonalNotes == nil || cachedPersonalNotesTimestamp <= effectiveTimestamp {
            cachedPersonalNotes = result
            cachedPersonalNotesTimestamp = effectiveTimestamp
            lock.unlock()
            return result
        } else {
            let existing = cachedPersonalNotes ?? result
            lock.unlock()
            return existing
        }
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
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = allNotes.firstIndex(where: { $0.courseworkId == courseworkId }) {
            if trimmed.isEmpty && allNotes[index].checklist.isEmpty {
                allNotes.remove(at: index)
            } else {
                let existing = allNotes[index]
                allNotes[index] = PersonalNote(
                    id: existing.id,
                    courseworkId: existing.courseworkId,
                    courseId: courseId ?? existing.courseId,
                    courseName: courseName ?? existing.courseName,
                    title: title.isEmpty ? existing.title : title,
                    content: trimmed,
                    checklist: existing.checklist,
                    dueDate: existing.dueDate,
                    isCompleted: existing.isCompleted,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
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

    public func cleanUpOrphanedNotes(validCourseworkIds: Set<String>) {
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        let originalCount = allNotes.count
        allNotes.removeAll { note in
            if let cwId = note.courseworkId, !cwId.isEmpty {
                return !validCourseworkIds.contains(cwId)
            }
            return false
        }
        if allNotes.count != originalCount {
            savePersonalNotes(allNotes)
        }
    }

    public func deletePersonalNote(id: String) {
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        allNotes.removeAll { $0.id == id }
        savePersonalNotes(allNotes)
    }

    public func togglePersonalNoteCompletion(id: String) {
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        if let index = allNotes.firstIndex(where: { $0.id == id }) {
            allNotes[index].isCompleted.toggle()
            let newStatus = allNotes[index].isCompleted
            if !allNotes[index].checklist.isEmpty {
                allNotes[index].checklist = allNotes[index].checklist.map { item in
                    var copy = item
                    copy.isCompleted = newStatus
                    return copy
                }
            }
            allNotes[index].updatedAt = Date()
            savePersonalNotes(allNotes)
        }
    }

    public func setPersonalNoteCompletion(id: String, isCompleted: Bool) {
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        if let index = allNotes.firstIndex(where: { $0.id == id }) {
            allNotes[index].isCompleted = isCompleted
            if !allNotes[index].checklist.isEmpty {
                allNotes[index].checklist = allNotes[index].checklist.map { item in
                    var copy = item
                    copy.isCompleted = isCompleted
                    return copy
                }
            }
            allNotes[index].updatedAt = Date()
            savePersonalNotes(allNotes)
        }
    }

    public func toggleChecklistItemCompletion(noteId: String, itemId: String) {
        lock.lock()
        defer { lock.unlock() }

        var allNotes = loadPersonalNotes()
        guard let noteIndex = allNotes.firstIndex(where: { $0.id == noteId }) else { return }
        guard let itemIndex = allNotes[noteIndex].checklist.firstIndex(where: { $0.id == itemId }) else { return }

        allNotes[noteIndex].checklist[itemIndex].isCompleted.toggle()
        allNotes[noteIndex].updatedAt = Date()

        let items = allNotes[noteIndex].checklist
        if !items.isEmpty && items.allSatisfy({ $0.isCompleted }) {
            allNotes[noteIndex].isCompleted = true
        } else if items.contains(where: { !$0.isCompleted }) && allNotes[noteIndex].isCompleted {
            allNotes[noteIndex].isCompleted = false
        }

        savePersonalNotes(allNotes)
    }

    public func getTomorrowPersonalNotes(notes: [PersonalNote]? = nil, includeCompleted: Bool = false) -> [PersonalNote] {
        let allNotes = notes ?? loadPersonalNotes()
        let calendar = ClassroomDateFormatters.gregorianCalendar
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
