import Foundation

@main
struct TestRunner {
    static func assertCondition(_ condition: Bool, _ message: String) {
        if !condition {
            print("❌ Assertion FAILED: \(message)")
            exit(1)
        } else {
            print("✅ PASSED: \(message)")
        }
    }

    static func main() {
        print("=== Running Apple Core Logic & Model Tests ===")

        // Test 1: resilient decoding of SubmissionStatus with unexpected values
        do {
            let jsonWithUnknownStatus = """
            {
                "id": "test_1",
                "courseId": "c_1",
                "courseName": "Math",
                "title": "Assignment Unknown Status",
                "state": "PUBLISHED",
                "status": "SOME_NEW_GOOGLE_STATUS_NOT_IN_ENUM"
            }
            """.data(using: .utf8)!

            let decoded = try JSONDecoder().decode(Coursework.self, from: jsonWithUnknownStatus)
            assertCondition(decoded.status == .pending, "Unknown submission status should fall back to .pending without crashing")
            assertCondition(!decoded.isManuallyCompleted, "Default isManuallyCompleted should be false")
        } catch {
            assertCondition(false, "Failed to decode Coursework with unknown status: \(error)")
        }

        // Test 2: Codable round-trip with isManuallyCompleted
        do {
            let now = Date()
            let futureDate = now.addingTimeInterval(86400)
            let original = Coursework(
                id: "cw_roundtrip",
                courseId: "course_1",
                courseName: "History",
                title: "Manual Done Task",
                dueDate: futureDate,
                status: .pending,
                isManuallyCompleted: true
            )

            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Coursework.self, from: encoded)

            assertCondition(decoded.isManuallyCompleted == true, "Encoded and decoded isManuallyCompleted flag must be preserved")
            assertCondition(decoded.isCompleted == true, "Task with isManuallyCompleted = true must evaluate isCompleted == true")
        } catch {
            assertCondition(false, "Codable round-trip error: \(error)")
        }

        // Test 3: Core Philosophy "triết lý: cứ hết hạn thì tính là đã hoàn thành"
        do {
            let now = Date()
            let pastDate = now.addingTimeInterval(-3600)
            let expiredTask = Coursework(
                id: "cw_expired",
                courseId: "course_1",
                courseName: "Science",
                title: "Past Due Task",
                dueDate: pastDate,
                status: .pending,
                isManuallyCompleted: false
            )

            assertCondition(expiredTask.isCompleted == true, "Expired task (dueDate < now) must be considered completed")
        }

        // Test 4: Future Pending Task
        do {
            let now = Date()
            let futureDate = now.addingTimeInterval(3600 * 24)
            let futureTask = Coursework(
                id: "cw_future",
                courseId: "course_1",
                courseName: "Literature",
                title: "Future Pending Task",
                dueDate: futureDate,
                status: .pending,
                isManuallyCompleted: false
            )

            assertCondition(futureTask.isCompleted == false, "Future pending task must NOT be considered completed")
        }

        // Test 5: TurnedIn / Returned status
        do {
            let futureDate = Date().addingTimeInterval(3600 * 24)
            let turnedInTask = Coursework(
                id: "cw_turned_in",
                courseId: "c1",
                courseName: "Math",
                title: "Turned In Task",
                dueDate: futureDate,
                status: .turnedIn
            )
            let returnedTask = Coursework(
                id: "cw_returned",
                courseId: "c1",
                courseName: "Math",
                title: "Returned Task",
                dueDate: futureDate,
                status: .returned
            )

            assertCondition(turnedInTask.isCompleted == true, "Turned in task must be completed")
            assertCondition(returnedTask.isCompleted == true, "Returned task must be completed")
        }

        // Test 6: Sorting logic - Incomplete first, then earlier due date, then alphabetical
        do {
            let now = Date()
            let future1 = now.addingTimeInterval(3600)
            let future2 = now.addingTimeInterval(7200)

            let completedItem = Coursework(id: "1", courseId: "c", courseName: "Course", title: "A Completed", dueDate: future1, status: .turnedIn)
            let urgentIncomplete = Coursework(id: "2", courseId: "c", courseName: "Course", title: "B Incomplete Soon", dueDate: future1, status: .pending)
            let laterIncomplete = Coursework(id: "3", courseId: "c", courseName: "Course", title: "C Incomplete Later", dueDate: future2, status: .pending)
            let laterIncompleteAlpha = Coursework(id: "4", courseId: "c", courseName: "Course", title: "A Incomplete Later", dueDate: future2, status: .pending)

            let items = [completedItem, laterIncomplete, urgentIncomplete, laterIncompleteAlpha]

            let sorted = items.sorted { first, second in
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

            assertCondition(sorted[0].id == "2", "First sorted item must be the soonest incomplete task")
            assertCondition(sorted[1].id == "4", "Second sorted item must be earlier in alphabetical order for same due date")
            assertCondition(sorted[2].id == "3", "Third sorted item must be later incomplete task")
            assertCondition(sorted[3].id == "1", "Completed task must be sorted last")
        }

        // Test 7: Active course filtering
        do {
            let courses: [Course] = [
                Course(id: "c1", name: "Math", isSelectedForWidget: true),
                Course(id: "c2", name: "Literature", isSelectedForWidget: false)
            ]
            let items: [Coursework] = [
                Coursework(id: "item1", courseId: "c1", courseName: "Math", title: "Math HW", status: .pending),
                Coursework(id: "item2", courseId: "c2", courseName: "Literature", title: "Literature HW", status: .pending),
                Coursework(id: "item3", courseId: "unknown", courseName: "Unknown", title: "Other HW", status: .pending)
            ]

            let allCourseIds = Set(courses.map { $0.id })
            let activeCourseIds = Set(courses.filter { $0.isSelectedForWidget }.map { $0.id })
            let filtered = items.filter { item in
                if allCourseIds.contains(item.courseId) {
                    return activeCourseIds.contains(item.courseId)
                }
                return true
            }

            assertCondition(filtered.count == 2, "Filtered items must keep active course items and uncatalogued items")
            assertCondition(filtered.contains { $0.id == "item1" }, "Active course item must be kept")
            assertCondition(!filtered.contains { $0.id == "item2" }, "Unselected course item must be filtered out")
            assertCondition(filtered.contains { $0.id == "item3" }, "Uncatalogued item must be preserved")
        }

        // Test 8: PersonalNote model, Codable round-trip, search index, and date bucketing
        do {
            let cal = Calendar.current
            let now = Date()
            guard let tomorrow = cal.date(byAdding: .day, value: 1, to: now) else {
                fatalError("Cannot calculate tomorrow")
            }

            let note = PersonalNote(
                id: "note_123",
                courseworkId: "cw_456",
                courseId: "c_math",
                courseName: "Toán học 12",
                title: "Ôn tập chương 1 Giải tích",
                content: "Làm bài tập trang 35 và nộp bản photo",
                dueDate: tomorrow,
                isCompleted: false
            )

            // Search normalization test
            let normalizedQuery = "giai tich".normalizedForVietnameseSearch()
            assertCondition(note.searchIndex.contains(normalizedQuery), "PersonalNote search index must match diacritic-free Vietnamese query")

            let queryTitle = "toan hoc".normalizedForVietnameseSearch()
            assertCondition(note.searchIndex.contains(queryTitle), "PersonalNote search index must match course name query")

            // Tomorrow date test
            assertCondition(note.isDueTomorrow, "PersonalNote with tomorrow dueDate must return isDueTomorrow == true")
            assertCondition(!note.isDueToday, "PersonalNote with tomorrow dueDate must return isDueToday == false")

            // Codable round-trip test
            let encoded = try JSONEncoder().encode(note)
            let decoded = try JSONDecoder().decode(PersonalNote.self, from: encoded)

            assertCondition(decoded.id == note.id, "Decoded note ID must match original")
            assertCondition(decoded.courseworkId == "cw_456", "Decoded courseworkId must match")
            assertCondition(decoded.title == note.title, "Decoded title must match")
            assertCondition(decoded.content == note.content, "Decoded content must match")
            assertCondition(decoded.isCompleted == false, "Decoded completion state must match")
        } catch {
            assertCondition(false, "PersonalNote test failed: \(error)")
        }

        print("=== All Apple Core Logic Tests Passed Successfully! ===")
    }
}
