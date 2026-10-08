import Foundation

@MainActor
public final class ClassroomAPIService: ObservableObject {
    public static let shared = ClassroomAPIService()

    @Published public private(set) var isSyncing: Bool = false
    @Published public var syncErrorMessage: String? = nil

    private init() {}

    public func syncAll() async {
        guard !isSyncing else { return }
        guard GoogleOAuthService.shared.isAuthenticated else {
            syncErrorMessage = "Chưa kết nối Google."
            return
        }

        isSyncing = true
        syncErrorMessage = nil

        defer {
            isSyncing = false
        }

        do {
            let accessToken = try await GoogleOAuthService.shared.getValidAccessToken()
            guard GoogleOAuthService.shared.isAuthenticated, !Task.isCancelled else { return }

            let fetchedCourses = try await fetchActiveCourses(accessToken: accessToken)
            guard GoogleOAuthService.shared.isAuthenticated, !Task.isCancelled else { return }

            let existingCourses = ClassroomStorage.shared.loadCourses()
            let existingMap = Dictionary(existingCourses.map { ($0.id, $0.isSelectedForWidget) }, uniquingKeysWith: { _, new in new })

            let mergedCourses = fetchedCourses.map { course in
                var updated = course
                if let isSelected = existingMap[course.id] {
                    updated.isSelectedForWidget = isSelected
                }
                return updated
            }
            ClassroomStorage.shared.saveCourses(mergedCourses)

            let selectedCourses = mergedCourses.filter(\.isSelectedForWidget)
            var allCoursework: [Coursework] = []
            let existingCoursework = ClassroomStorage.shared.loadCoursework()

            // Chunk requests to avoid Google's 10 QPS quota
            let chunkSize = 3
            for startIndex in stride(from: 0, to: selectedCourses.count, by: chunkSize) {
                guard GoogleOAuthService.shared.isAuthenticated, !Task.isCancelled else { return }
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
                            allCoursework.append(contentsOf: items)
                        } else {
                            // Keep cached coursework if fetch fails
                            let preserved = existingCoursework.filter { $0.courseId == courseId }
                            allCoursework.append(contentsOf: preserved)
                        }
                    }
                }
            }

            guard GoogleOAuthService.shared.isAuthenticated, !Task.isCancelled else { return }

            let unselectedIds = Set(mergedCourses.filter { !$0.isSelectedForWidget }.map(\.id))
            let preservedItems = existingCoursework.filter { unselectedIds.contains($0.courseId) }
            allCoursework.append(contentsOf: preservedItems)

            // Keep manual checklist completion if not yet turned in on Google
            let existingStatusMap = Dictionary(existingCoursework.map { ($0.id, $0.status) }, uniquingKeysWith: { _, new in new })
            let finalCoursework = allCoursework.map { item -> Coursework in
                var updated = item
                if let oldStatus = existingStatusMap[item.id], oldStatus == .turnedIn, !updated.isCompleted {
                    updated.status = .turnedIn
                }
                return updated
            }

            ClassroomStorage.shared.saveCoursework(finalCoursework)
            ClassroomStorage.shared.saveLastSyncTime(Date())
        } catch {
            syncErrorMessage = "Lỗi đồng bộ: \(error.localizedDescription)"
        }
    }

    private func fetchActiveCourses(accessToken: String) async throws -> [Course] {
        var coursesMap: [String: Course] = [:]

        // 1. Fetch courses where user is enrolled as a student (required by Classroom API for student accounts)
        let studentCourses = await fetchCoursesPage(accessToken: accessToken, filterKey: "studentId", filterValue: "me", courseState: "ACTIVE")
        for course in studentCourses {
            coursesMap[course.id] = course
        }

        // 2. Fetch courses where user is a teacher (for teacher accounts)
        let teacherCourses = await fetchCoursesPage(accessToken: accessToken, filterKey: "teacherId", filterValue: "me", courseState: "ACTIVE")
        for course in teacherCourses {
            coursesMap[course.id] = course
        }

        // 3. Fallback: if empty, try fetching without role filter (for domain admins / creators)
        if coursesMap.isEmpty {
            let adminCourses = await fetchCoursesPage(accessToken: accessToken, filterKey: nil, filterValue: nil, courseState: "ACTIVE")
            for course in adminCourses {
                coursesMap[course.id] = course
            }
        }

        // 4. Fallback 2: if still empty, try without courseStates=ACTIVE constraint in case courses have other states
        if coursesMap.isEmpty {
            let studentAllStateCourses = await fetchCoursesPage(accessToken: accessToken, filterKey: "studentId", filterValue: "me", courseState: nil)
            for course in studentAllStateCourses {
                coursesMap[course.id] = course
            }
            let teacherAllStateCourses = await fetchCoursesPage(accessToken: accessToken, filterKey: "teacherId", filterValue: "me", courseState: nil)
            for course in teacherAllStateCourses {
                coursesMap[course.id] = course
            }
        }

        return Array(coursesMap.values)
    }

    private func fetchCoursesPage(
        accessToken: String,
        filterKey: String?,
        filterValue: String?,
        courseState: String? = "ACTIVE"
    ) async -> [Course] {
        var courses: [Course] = []
        var pageToken: String? = nil
        var pageCount = 0

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses") else { break }
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
            guard let url = components.url else { break }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    break
                }

                let decoded = try JSONDecoder().decode(GoogleCoursesListResponse.self, from: data)
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
                pageToken = decoded.nextPageToken
                pageCount += 1
            } catch {
                break
            }
        } while pageToken != nil && pageCount < 10

        return courses
    }

    private func fetchCourseworkForCourse(course: Course, accessToken: String) async throws -> [Coursework] {
        async let rawCourseworkFetch = fetchRawCoursework(courseId: course.id, accessToken: accessToken)
        async let submissionsMapFetch = fetchSubmissionsMap(courseId: course.id, accessToken: accessToken)

        let rawItems = try await rawCourseworkFetch
        let submissionsMap = await submissionsMapFetch
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
                    if submission?.late == true || (dueDate != nil && dueDate! < now) {
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

    private func fetchRawCoursework(courseId: String, accessToken: String) async throws -> [GoogleCourseworkRawItem] {
        var allItems: [GoogleCourseworkRawItem] = []
        var pageToken: String? = nil
        var pageCount = 0

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork") else { break }
            var queryItems = [
                URLQueryItem(name: "courseWorkStates", value: "PUBLISHED"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
            if let token = pageToken, !token.isEmpty {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            components.queryItems = queryItems
            guard let url = components.url else { break }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                break
            }

            if let decoded = try? JSONDecoder().decode(GoogleCourseworkListResponse.self, from: data),
               let items = decoded.courseWork {
                allItems.append(contentsOf: items)
                pageToken = decoded.nextPageToken
            } else {
                break
            }
            pageCount += 1
        } while pageToken != nil && pageCount < 10

        // Fallback: If courseWorkStates=PUBLISHED returned nothing, retry without courseWorkStates filter
        if allItems.isEmpty {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork") else { return allItems }
            components.queryItems = [URLQueryItem(name: "pageSize", value: "50")]
            if let url = components.url {
                var request = URLRequest(url: url)
                request.timeoutInterval = 15
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let (data, response) = try? await URLSession.shared.data(for: request),
                   let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                   let decoded = try? JSONDecoder().decode(GoogleCourseworkListResponse.self, from: data),
                   let items = decoded.courseWork {
                    allItems.append(contentsOf: items)
                }
            }
        }

        return allItems
    }

    private func fetchSubmissionsMap(courseId: String, accessToken: String) async -> [String: GoogleSubmissionItem] {
        var map: [String: GoogleSubmissionItem] = [:]
        var pageToken: String? = nil
        var pageCount = 0

        repeat {
            guard var components = URLComponents(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork/-/studentSubmissions") else { break }
            var queryItems = [
                URLQueryItem(name: "userId", value: "me"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
            if let token = pageToken, !token.isEmpty {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            components.queryItems = queryItems
            guard let url = components.url else { break }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    break
                }
                let decoded = try JSONDecoder().decode(GoogleSubmissionsListResponse.self, from: data)
                for item in decoded.studentSubmissions ?? [] {
                    if let cwId = item.courseWorkId, !cwId.isEmpty {
                        map[cwId] = item
                    }
                }
                pageToken = decoded.nextPageToken
                pageCount += 1
            } catch {
                break
            }
        } while pageToken != nil && pageCount < 10

        return map
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func parseGoogleDueDate(date: GoogleDateItem?, time: GoogleTimeItem?) -> Date? {
        guard let date, let year = date.year, let month = date.month, let day = date.day else {
            return nil
        }

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        if let time {
            // Classroom API returns TimeOfDay in UTC; proto3 omits 0 fields
            dateComponents.hour = time.hours ?? 0
            dateComponents.minute = time.minutes ?? 0
            dateComponents.second = time.seconds ?? 0
            return Self.utcCalendar.date(from: dateComponents)
        } else {
            dateComponents.hour = 23
            dateComponents.minute = 59
            dateComponents.second = 59
            return Calendar.current.date(from: dateComponents)
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
