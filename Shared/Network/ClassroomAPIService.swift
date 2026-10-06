import Foundation

@MainActor
public final class ClassroomAPIService: ObservableObject {
    public static let shared = ClassroomAPIService()

    @Published public private(set) var isSyncing: Bool = false
    @Published public var syncErrorMessage: String? = nil

    private init() {}

    public func syncAll() async {
        guard GoogleOAuthService.shared.isAuthenticated else {
            syncErrorMessage = "Chưa kết nối Google."
            return
        }

        isSyncing = true
        syncErrorMessage = nil

        do {
            let accessToken = try await GoogleOAuthService.shared.getValidAccessToken()

            let fetchedCourses = try await fetchActiveCourses(accessToken: accessToken)
            let existingCourses = ClassroomStorage.shared.loadCourses()
            let existingMap = Dictionary(uniqueKeysWithValues: existingCourses.map { ($0.id, $0.isSelectedForWidget) })

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

            await withTaskGroup(of: [Coursework]?.self) { group in
                for course in selectedCourses {
                    group.addTask {
                        do {
                            return try await self.fetchCourseworkForCourse(course: course, accessToken: accessToken)
                        } catch {
                            print("Lỗi fetch lớp \(course.name): \(error.localizedDescription)")
                            return nil
                        }
                    }
                }

                for await result in group {
                    if let items = result {
                        allCoursework.append(contentsOf: items)
                    }
                }
            }

            let unselectedIds = Set(mergedCourses.filter { !$0.isSelectedForWidget }.map(\.id))
            let existingCoursework = ClassroomStorage.shared.loadCoursework()
            let preservedItems = existingCoursework.filter { unselectedIds.contains($0.courseId) }
            allCoursework.append(contentsOf: preservedItems)

            ClassroomStorage.shared.saveCoursework(allCoursework)
            ClassroomStorage.shared.saveLastSyncTime(Date())
            ClassroomStorage.shared.notifyWidgetReload()
        } catch {
            syncErrorMessage = "Lỗi đồng bộ: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    private func fetchActiveCourses(accessToken: String) async throws -> [Course] {
        guard let url = URL(string: "https://classroom.googleapis.com/v1/courses?courseStates=ACTIVE") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ClassroomAPIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không lấy được danh sách lớp"])
        }

        let decoded = try JSONDecoder().decode(GoogleCoursesListResponse.self, from: data)
        return (decoded.courses ?? []).map { item in
            Course(
                id: item.id,
                name: item.name,
                section: item.section,
                descriptionHeading: item.descriptionHeading,
                room: item.room,
                alternateLink: item.alternateLink,
                isSelectedForWidget: true
            )
        }
    }

    private func fetchCourseworkForCourse(course: Course, accessToken: String) async throws -> [Coursework] {
        async let rawCourseworkFetch = fetchRawCoursework(courseId: course.id, accessToken: accessToken)
        async let submissionsMapFetch = fetchSubmissionsMap(courseId: course.id, accessToken: accessToken)

        let rawItems = try await rawCourseworkFetch
        let submissionsMap = await submissionsMapFetch
        let now = Date()

        return rawItems.map { raw in
            let submission = submissionsMap[raw.id]
            let dueDate = parseGoogleDueDate(date: raw.dueDate, time: raw.dueTime)

            let status: SubmissionStatus
            if let state = submission?.state {
                switch state {
                case "TURNED_IN":
                    status = .turnedIn
                case "RETURNED":
                    status = .returned
                default:
                    if let dueDate, Calendar.current.isDateInToday(dueDate) || dueDate < now {
                        status = .turnedIn
                    } else if submission?.late == true {
                        status = .late
                    } else {
                        status = .pending
                    }
                }
            } else if let dueDate, Calendar.current.isDateInToday(dueDate) || dueDate < now {
                status = .turnedIn
            } else {
                status = .pending
            }

            return Coursework(
                id: raw.id,
                courseId: course.id,
                courseName: course.name,
                title: raw.title,
                description: raw.description,
                alternateLink: raw.alternateLink,
                dueDate: dueDate,
                status: status,
                maxPoints: raw.maxPoints
            )
        }
    }

    private func fetchRawCoursework(courseId: String, accessToken: String) async throws -> [GoogleCourseworkRawItem] {
        guard let url = URL(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork?courseWorkStates=PUBLISHED") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let decoded = try JSONDecoder().decode(GoogleCourseworkListResponse.self, from: data)
        return decoded.courseWork ?? []
    }

    private func fetchSubmissionsMap(courseId: String, accessToken: String) async -> [String: GoogleSubmissionItem] {
        guard let url = URL(string: "https://classroom.googleapis.com/v1/courses/\(courseId)/courseWork/-/studentSubmissions?userId=me") else {
            return [:]
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return [:]
            }
            let decoded = try JSONDecoder().decode(GoogleSubmissionsListResponse.self, from: data)
            var map: [String: GoogleSubmissionItem] = [:]
            for item in decoded.studentSubmissions ?? [] {
                map[item.courseWorkId] = item
            }
            return map
        } catch {
            return [:]
        }
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

        if let time, let hour = time.hours {
            dateComponents.hour = hour
            dateComponents.minute = time.minutes ?? 0
            dateComponents.second = 0
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
}

private struct GoogleCourseItem: Codable {
    let id: String
    let name: String
    let section: String?
    let descriptionHeading: String?
    let room: String?
    let alternateLink: String?
}

private struct GoogleCourseworkListResponse: Codable {
    let courseWork: [GoogleCourseworkRawItem]?
}

private struct GoogleCourseworkRawItem: Codable {
    let id: String
    let title: String
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
}

private struct GoogleSubmissionsListResponse: Codable {
    let studentSubmissions: [GoogleSubmissionItem]?
}

private struct GoogleSubmissionItem: Codable {
    let id: String
    let courseWorkId: String
    let state: String?
    let late: Bool?
}
