import Foundation

private final class MockClassroomProtocol: URLProtocol {
    static var handler: (URLRequest) throws -> (Int, String) = { _ in (200, "{}") }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, body) = try Self.handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

@main
struct AppleSyncLogicTests {
    static var failures = 0

    static func check(_ condition: Bool, _ message: String) {
        print("\(condition ? "PASS" : "FAIL"): \(message)")
        if !condition { failures += 1 }
    }

    @MainActor
    static func main() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockClassroomProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let api = ClassroomAPIService(session: session)
        let course = Course(id: "c", name: "Math")

        MockClassroomProtocol.handler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
            let page = Int(query.first { $0.name == "pageToken" }?.value ?? "0") ?? 0
            let next = page < 10 ? ",\"nextPageToken\":\"\(page + 1)\"" : ""
            if request.url!.path.hasSuffix("studentSubmissions") {
                return (200, "{\"studentSubmissions\":[{\"courseWorkId\":\"cw\(page)\",\"state\":\"TURNED_IN\"}]\(next)}")
            }
            return (200, "{\"courseWork\":[{\"id\":\"cw\(page)\",\"title\":\"Task\"}]\(next)}")
        }
        do {
            let items = try await api.fetchCourseworkForCourse(course: course, accessToken: "test")
            check(items.count == 11 && items.last?.status == .turnedIn, "All coursework and submissions pages must load beyond page ten")
        } catch { check(false, "Pagination failed: \(error)") }

        MockClassroomProtocol.handler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
            return query.contains { $0.name == "studentId" }
                ? (200, "{\"courses\":[{\"id\":\"student\",\"name\":\"Math\"}]}") : (403, "{}")
        }
        do {
            _ = try await api.fetchActiveCourses(accessToken: "test")
            check(false, "Partial course list must fail when authoritative fallback also fails")
        } catch { check(true, "Partial course list rejected") }

        MockClassroomProtocol.handler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
            if query.contains(where: { $0.name == "studentId" }) {
                if query.contains(where: { $0.name == "pageToken" }) {
                    throw URLError(.networkConnectionLost)
                }
                return (200, "{\"courses\":[{\"id\":\"first\",\"name\":\"Math\"}],\"nextPageToken\":\"second\"}")
            }
            if query.contains(where: { $0.name == "teacherId" }) { return (200, "{}") }
            return (403, "{}")
        }
        do {
            _ = try await api.fetchActiveCourses(accessToken: "test")
            check(false, "Transport failure after page one must not return a partial course list")
        } catch { check(true, "Transport failure after page one rejected") }

        MockClassroomProtocol.handler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
            if query.contains(where: { $0.name == "studentId" }) { return (403, "{}") }
            if query.contains(where: { $0.name == "teacherId" }) { return (200, "{}") }
            return (200, "{\"courses\":[{\"id\":\"all\",\"name\":\"Math\"}]}")
        }
        do {
            let courses = try await api.fetchActiveCourses(accessToken: "test")
            check(courses.map(\.id) == ["all"], "Complete fallback must recover from a failed role query")
        } catch { check(false, "Authoritative fallback failed: \(error)") }

        MockClassroomProtocol.handler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
            return query.contains { $0.name == "courseStates" && $0.value == "ACTIVE" }
                ? (200, "{}") : (200, "{\"courses\":[{\"id\":\"archived\",\"name\":\"Old\"}]}")
        }
        do {
            let courses = try await api.fetchActiveCourses(accessToken: "test")
            check(courses.isEmpty, "Empty active course list must not import archived courses")
        } catch { check(false, "Empty active courses failed: \(error)") }

        MockClassroomProtocol.handler = { _ in
            (200, "{\"courseWork\":[{\"id\":\"cw\",\"title\":\"Task\"}],\"nextPageToken\":\"repeat\"}")
        }
        do {
            _ = try await api.fetchCourseworkForCourse(course: course, accessToken: "test")
            check(false, "Repeated page tokens must fail rather than return truncated data")
        } catch { check(true, "Repeated page tokens rejected") }

        exit(failures == 0 ? 0 : 1)
    }
}
