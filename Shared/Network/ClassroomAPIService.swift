import Foundation

public enum ClassroomAPIError: LocalizedError {
    case httpError(statusCode: Int)
    case invalidResponse
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "Máy chủ phản hồi mã lỗi \(code)"
        case .invalidResponse:
            return "Phản hồi từ máy chủ không hợp lệ"
        case .invalidURL:
            return "Đường dẫn không hợp lệ"
        }
    }
}

@MainActor
public final class ClassroomAPIService: ObservableObject {
    public static let shared = ClassroomAPIService()

    @Published public private(set) var isSyncing: Bool = false
    @Published public var syncErrorMessage: String? = nil

    private let session: URLSession
    private var syncingSessionID: UUID?
    private var syncWaiters: [UUID: [CheckedContinuation<Void, Never>]] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    public func syncAll() async {
        let auth = GoogleOAuthService.shared
        let sessionID = auth.sessionID
        await syncAll(sessionID: sessionID, getAccessToken: auth.getValidAccessToken) {
            auth.isAuthenticated && auth.sessionID == sessionID
        }
    }

    func syncAll(sessionID: UUID, getAccessToken: () async throws -> String, isSessionActive: () -> Bool) async {
        if syncingSessionID == sessionID {
            await withCheckedContinuation { continuation in
                syncWaiters[sessionID, default: []].append(continuation)
            }
            return
        }
        guard isSessionActive() else {
            syncErrorMessage = "Chưa kết nối Google."
            return
        }

        syncingSessionID = sessionID
        isSyncing = true
        syncErrorMessage = nil

        defer {
            if syncingSessionID == sessionID {
                syncingSessionID = nil
                isSyncing = false
            }
            for waiter in syncWaiters.removeValue(forKey: sessionID) ?? [] {
                waiter.resume()
            }
        }

        do {
            let accessToken = try await getAccessToken()
            guard isSessionActive(), !Task.isCancelled else { return }

            let fetchedCourses = try await fetchActiveCourses(accessToken: accessToken)
            guard isSessionActive(), !Task.isCancelled else { return }

            let storage = ClassroomStorage.shared
            let selectedCourses = storage.mergeCourseSelections(into: fetchedCourses).filter(\.isSelectedForWidget)
            var fetchedCoursework: [Coursework] = []
            var hasAnyFetchErrors = false
            var fetchedCourseIds = Set<String>()

            if !selectedCourses.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            let chunkSize = 2
            for startIndex in stride(from: 0, to: selectedCourses.count, by: chunkSize) {
                guard isSessionActive(), !Task.isCancelled else { return }
                let chunk = Array(selectedCourses[startIndex..<min(startIndex + chunkSize, selectedCourses.count)])
                await withTaskGroup(of: (String, [Coursework]?).self) { group in
                    for course in chunk {
                        group.addTask {
                            do {
                                let items = try await self.fetchCourseworkForCourse(course: course, accessToken: accessToken)
                                return (course.id, items)
                            } catch {
                                print("Lỗi fetch lớp \(course.name): \(error.localizedDescription)")
                                return (course.id, nil)
                            }
                        }
                    }

                    for await (courseId, result) in group {
                        if let items = result {
                            fetchedCourseIds.insert(courseId)
                            fetchedCoursework.append(contentsOf: items)
                        } else {
                            hasAnyFetchErrors = true
                        }
                    }
                }

                if startIndex + chunkSize < selectedCourses.count {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                }
            }

            guard isSessionActive(), !Task.isCancelled else { return }

            storage.saveSyncResult(courses: fetchedCourses, coursework: fetchedCoursework, fetchedCourseIds: fetchedCourseIds)
            if hasAnyFetchErrors {
                syncErrorMessage = "Một số lớp chưa đồng bộ được. Đã giữ dữ liệu cũ; vui lòng thử lại."
            } else {
                storage.saveLastSyncTime(Date())
            }
            storage.saveUserLoggedIn(true)
        } catch {
            if !isSessionActive() || Task.isCancelled || (error as? URLError)?.code == .cancelled {
                return
            }
            syncErrorMessage = "Lỗi đồng bộ: \(error.localizedDescription)"
        }
    }

    nonisolated func fetchActiveCourses(accessToken: String) async throws -> [Course] {
        var coursesMap: [String: Course] = [:]
        var lastError: Error?

        do {
            let studentCourses = try await fetchCoursesPage(accessToken: accessToken, filterKey: "studentId", filterValue: "me", courseState: "ACTIVE")
            for course in studentCourses {
                coursesMap[course.id] = course
            }
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw error }
            lastError = error
        }

        do {
            let teacherCourses = try await fetchCoursesPage(accessToken: accessToken, filterKey: "teacherId", filterValue: "me", courseState: "ACTIVE")
            for course in teacherCourses {
                coursesMap[course.id] = course
            }
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw error }
            if lastError == nil { lastError = error }
        }

        if coursesMap.isEmpty || lastError != nil {
            // Only a complete listing can safely drive cache deletion.
            return try await fetchCoursesPage(accessToken: accessToken, filterKey: nil, filterValue: nil, courseState: "ACTIVE")
        }

        return Array(coursesMap.values)
    }

    private nonisolated func dataWithRetry(for request: URLRequest, maxRetries: Int = 2) async throws -> (Data, URLResponse) {
        var attempt = 0
        while true {
            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw error }
                if attempt < maxRetries {
                    attempt += 1
                    let delay = UInt64(500_000_000) * (1 << attempt)
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                throw error
            }

            if let httpResponse = response as? HTTPURLResponse,
               (httpResponse.statusCode == 429 || httpResponse.statusCode == 503),
               attempt < maxRetries {
                attempt += 1
                var delayNs = UInt64(500_000_000) * (1 << attempt)
                if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let seconds = Double(retryAfterHeader), seconds > 0 {
                    delayNs = UInt64(seconds * 1_000_000_000)
                }
                try await Task.sleep(nanoseconds: delayNs)
                continue
            }

            return (data, response)
        }
    }

    private nonisolated func fetchCoursesPage(
        accessToken: String,
        filterKey: String?,
        filterValue: String?,
        courseState: String? = "ACTIVE"
    ) async throws -> [Course] {
        var courses: [Course] = []
        var pageToken: String? = nil
        var seenPageTokens = Set<String>()

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses") else {
                throw ClassroomAPIError.invalidURL
            }
            var queryItems = [
                URLQueryItem(name: "pageSize", value: "50")
            ]
            if let courseState {
                queryItems.append(URLQueryItem(name: "courseStates", value: courseState))
            }
            if let filterKey, let filterValue {
                queryItems.append(URLQueryItem(name: filterKey, value: filterValue))
            }
            if let token = pageToken, !token.isEmpty {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            components.queryItems = queryItems
            guard let url = components.url else {
                throw ClassroomAPIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await dataWithRetry(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClassroomAPIError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ClassroomAPIError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoded = try Self.jsonDecoder.decode(GoogleCoursesListResponse.self, from: data)
            if let items = decoded.courses {
                let mapped = items.compactMap { item -> Course? in
                    guard let id = item.id, !id.isEmpty, let name = item.name, !name.isEmpty else { return nil }
                    return Course(
                        id: id,
                        name: name,
                        section: item.section,
                        descriptionHeading: item.descriptionHeading,
                        room: item.room,
                        alternateLink: item.alternateLink,
                        isSelectedForWidget: true
                    )
                }
                courses.append(contentsOf: mapped)
            }
            pageToken = decoded.nextPageToken.flatMap { $0.isEmpty ? nil : $0 }
            if let pageToken {
                guard seenPageTokens.insert(pageToken).inserted else { throw ClassroomAPIError.invalidResponse }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        } while pageToken != nil

        return courses
    }

    nonisolated func fetchCourseworkForCourse(course: Course, accessToken: String) async throws -> [Coursework] {
        async let rawCourseworkFetch = fetchRawCoursework(courseId: course.id, accessToken: accessToken)
        async let submissionsMapFetch = fetchSubmissionsMap(courseId: course.id, accessToken: accessToken)

        let rawItems = try await rawCourseworkFetch
        let submissionsMap = try await submissionsMapFetch
        let now = Date()

        return rawItems.compactMap { raw in
            guard let id = raw.id, !id.isEmpty else { return nil }
            let submission = submissionsMap[id]
            let dueDate = parseGoogleDueDate(date: raw.dueDate, time: raw.dueTime)

            let status: SubmissionStatus
            if let state = submission?.state {
                switch state {
                case "TURNED_IN", "STUDENT_EDITED_AFTER_TURN_IN":
                    status = .turnedIn
                case "RETURNED":
                    status = .returned
                default:
                    if submission?.late == true || (dueDate.map { $0 < now } ?? false) {
                        status = .late
                    } else {
                        status = .pending
                    }
                }
            } else if let dueDate, dueDate < now {
                status = .late
            } else {
                status = .pending
            }

            return Coursework(
                id: id,
                courseId: course.id,
                courseName: course.name,
                title: raw.title ?? "Bài tập không có tiêu đề",
                description: raw.description,
                alternateLink: raw.alternateLink,
                dueDate: dueDate,
                status: status,
                maxPoints: raw.maxPoints
            )
        }
    }

    private nonisolated func fetchRawCoursework(courseId: String, accessToken: String) async throws -> [GoogleCourseworkRawItem] {
        var allItems: [GoogleCourseworkRawItem] = []
        var pageToken: String? = nil
        var seenPageTokens = Set<String>()

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork") else { throw ClassroomAPIError.invalidURL }
            var queryItems = [
                URLQueryItem(name: "courseWorkStates", value: "PUBLISHED"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
            if let token = pageToken, !token.isEmpty {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            components.queryItems = queryItems
            guard let url = components.url else { throw ClassroomAPIError.invalidURL }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await dataWithRetry(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClassroomAPIError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ClassroomAPIError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoded = try Self.jsonDecoder.decode(GoogleCourseworkListResponse.self, from: data)
            if let items = decoded.courseWork {
                allItems.append(contentsOf: items)
            }
            pageToken = decoded.nextPageToken.flatMap { $0.isEmpty ? nil : $0 }
            if let pageToken {
                guard seenPageTokens.insert(pageToken).inserted else { throw ClassroomAPIError.invalidResponse }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        } while pageToken != nil

        return allItems
    }

    private nonisolated func fetchSubmissionsMap(courseId: String, accessToken: String) async throws -> [String: GoogleSubmissionItem] {
        var map: [String: GoogleSubmissionItem] = [:]
        var pageToken: String? = nil
        var seenPageTokens = Set<String>()

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork/-/studentSubmissions") else { throw ClassroomAPIError.invalidURL }
            var queryItems = [
                URLQueryItem(name: "userId", value: "me"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
            if let token = pageToken, !token.isEmpty {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            components.queryItems = queryItems
            guard let url = components.url else { throw ClassroomAPIError.invalidURL }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await dataWithRetry(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClassroomAPIError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ClassroomAPIError.httpError(statusCode: httpResponse.statusCode)
            }
            let decoded = try Self.jsonDecoder.decode(GoogleSubmissionsListResponse.self, from: data)
            for item in decoded.studentSubmissions ?? [] {
                if let cwId = item.courseWorkId, !cwId.isEmpty {
                    map[cwId] = item
                }
            }
            pageToken = decoded.nextPageToken.flatMap { $0.isEmpty ? nil : $0 }
            if let pageToken {
                guard seenPageTokens.insert(pageToken).inserted else { throw ClassroomAPIError.invalidResponse }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        } while pageToken != nil

        return map
    }

    private nonisolated static let jsonDecoder = JSONDecoder()

    private nonisolated static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private nonisolated static let localCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    private nonisolated func parseGoogleDueDate(date: GoogleDateItem?, time: GoogleTimeItem?) -> Date? {
        guard let date, let year = date.year, let month = date.month, let day = date.day else {
            return nil
        }

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        if let time, (time.hours != nil || time.minutes != nil || time.seconds != nil) {
            dateComponents.hour = time.hours ?? 0
            dateComponents.minute = time.minutes ?? 0
            dateComponents.second = time.seconds ?? 0
            return Self.utcCalendar.date(from: dateComponents)
        } else {
            dateComponents.hour = 23
            dateComponents.minute = 59
            dateComponents.second = 59
            return Self.localCalendar.date(from: dateComponents)
        }
    }
}

private struct GoogleCoursesListResponse: Codable {
    let courses: [GoogleCourseItem]?
    let nextPageToken: String?
}

private struct GoogleCourseItem: Codable {
    let id: String?
    let name: String?
    let section: String?
    let descriptionHeading: String?
    let room: String?
    let alternateLink: String?
}

private struct GoogleCourseworkListResponse: Codable {
    let courseWork: [GoogleCourseworkRawItem]?
    let nextPageToken: String?
}

private struct GoogleCourseworkRawItem: Codable {
    let id: String?
    let title: String?
    let description: String?
    let alternateLink: String?
    let dueDate: GoogleDateItem?
    let dueTime: GoogleTimeItem?
    let maxPoints: Double?
}

private struct GoogleDateItem: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
}

private struct GoogleTimeItem: Codable {
    let hours: Int?
    let minutes: Int?
    let seconds: Int?
}

private struct GoogleSubmissionsListResponse: Codable {
    let studentSubmissions: [GoogleSubmissionItem]?
    let nextPageToken: String?
}

private struct GoogleSubmissionItem: Codable {
    let id: String?
    let courseWorkId: String?
    let state: String?
    let late: Bool?
}
