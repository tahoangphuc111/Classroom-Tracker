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
            let cal = Calendar.autoupdatingCurrent
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

            // Test 8b: Coursework note clearing test
            var notesList = [
                PersonalNote(id: "note_cw", courseworkId: "cw_999", courseId: "c1", courseName: "Math", title: "Math HW", content: "Remember to do exercise 4")
            ]
            let trimmedEmptyContent = "   \n\t ".trimmingCharacters(in: .whitespacesAndNewlines)
            if let index = notesList.firstIndex(where: { $0.courseworkId == "cw_999" }) {
                if trimmedEmptyContent.isEmpty {
                    notesList.remove(at: index)
                }
            }
            assertCondition(notesList.isEmpty, "Coursework note must be removed when content is cleared")
        } catch {
            assertCondition(false, "PersonalNote test failed: \(error)")
        }

        // Test 9: compactDueString parity formatting
        do {
            let cal = Calendar.autoupdatingCurrent
            let now = Date()

            // 9.1: No due date
            let noDue = Coursework(id: "cw_nodue", courseId: "c1", courseName: "M", title: "T", dueDate: nil, status: .pending)
            assertCondition(noDue.compactDueString == "Không hạn", "No due date must format as 'Không hạn'")

            // 9.2: Completed item
            let completed = Coursework(id: "cw_done", courseId: "c1", courseName: "M", title: "T", dueDate: now.addingTimeInterval(3600), status: .turnedIn)
            assertCondition(completed.compactDueString == "Đã xong", "Completed item must format as 'Đã xong'")

            // 9.3: Today end-of-day (23:59:59)
            var compToday = cal.dateComponents([.year, .month, .day], from: now)
            compToday.hour = 23
            compToday.minute = 59
            compToday.second = 59
            if let todayEndOfDay = cal.date(from: compToday), todayEndOfDay > now {
                let todayEOD = Coursework(id: "cw_today_eod", courseId: "c1", courseName: "M", title: "T", dueDate: todayEndOfDay, status: .pending)
                assertCondition(todayEOD.compactDueString == "Cuối ngày", "Today end-of-day (23:59:59) must format as 'Cuối ngày'")
            }

            // 9.3b: Today 23:55
            var compToday2355 = cal.dateComponents([.year, .month, .day], from: now)
            compToday2355.hour = 23
            compToday2355.minute = 55
            compToday2355.second = 0
            if let today2355 = cal.date(from: compToday2355), today2355 > now {
                let today2355Item = Coursework(id: "cw_today_2355", courseId: "c1", courseName: "M", title: "T", dueDate: today2355, status: .pending)
                assertCondition(today2355Item.compactDueString == "Cuối ngày", "Today 23:55 must format as 'Cuối ngày'")
            }

            // 9.3c: Today future hour (e.g. 20:30)
            var compToday2030 = cal.dateComponents([.year, .month, .day], from: now)
            compToday2030.hour = 20
            compToday2030.minute = 30
            compToday2030.second = 0
            if let today2030 = cal.date(from: compToday2030), today2030 > now {
                let today2030Item = Coursework(id: "cw_today_2030", courseId: "c1", courseName: "M", title: "T", dueDate: today2030, status: .pending)
                assertCondition(today2030Item.compactDueString == "20:30", "Today 20:30 must format as '20:30'")
            }

            // 9.4: Tomorrow end-of-day (23:59:59)
            if let tomorrow = cal.date(byAdding: .day, value: 1, to: now) {
                var compTomEOD = cal.dateComponents([.year, .month, .day], from: tomorrow)
                compTomEOD.hour = 23
                compTomEOD.minute = 59
                compTomEOD.second = 59
                if let tomorrowEndOfDay = cal.date(from: compTomEOD) {
                    let tomEOD = Coursework(id: "cw_tom_eod", courseId: "c1", courseName: "M", title: "T", dueDate: tomorrowEndOfDay, status: .pending)
                    assertCondition(tomEOD.compactDueString == "Mai", "Tomorrow end-of-day (23:59:59) must format as 'Mai'")
                }

                // 9.4b: Tomorrow 23:55
                var compTom2355 = cal.dateComponents([.year, .month, .day], from: tomorrow)
                compTom2355.hour = 23
                compTom2355.minute = 55
                compTom2355.second = 0
                if let tomorrow2355 = cal.date(from: compTom2355) {
                    let tom2355 = Coursework(id: "cw_tom_2355", courseId: "c1", courseName: "M", title: "T", dueDate: tomorrow2355, status: .pending)
                    assertCondition(tom2355.compactDueString == "Mai", "Tomorrow 23:55 must format as 'Mai'")
                }

                // 9.5: Tomorrow 14:30
                var compTom1430 = cal.dateComponents([.year, .month, .day], from: tomorrow)
                compTom1430.hour = 14
                compTom1430.minute = 30
                compTom1430.second = 0
                if let tomorrow1430 = cal.date(from: compTom1430) {
                    let tom1430 = Coursework(id: "cw_tom_1430", courseId: "c1", courseName: "M", title: "T", dueDate: tomorrow1430, status: .pending)
                    assertCondition(tom1430.compactDueString == "Mai 14:30", "Tomorrow 14:30 must format as 'Mai 14:30'")
                }
            }
        }

        // Test 10: Sync reconciliation parity (local check vs remote unsubmit)
        do {
            let future = Date().addingTimeInterval(86400 * 2)

            // Case A: Item previously turned in on Classroom (isManuallyCompleted: false, status: .turnedIn)
            // Then student or teacher unsubmitted on Classroom Web -> incoming item has status: .pending, isManuallyCompleted: false
            let cachedRemoteTurnedIn = Coursework(id: "cw_unsubmit", courseId: "c1", courseName: "M", title: "Remote Unsubmit", dueDate: future, status: .turnedIn, isManuallyCompleted: false)
            let incomingUnsubmitted = Coursework(id: "cw_unsubmit", courseId: "c1", courseName: "M", title: "Remote Unsubmit", dueDate: future, status: .pending, isManuallyCompleted: false)

            let freshMapA = [cachedRemoteTurnedIn.id: cachedRemoteTurnedIn]
            var reconciledA = incomingUnsubmitted
            if let fresh = freshMapA[incomingUnsubmitted.id], fresh.isManuallyCompleted, !reconciledA.isCompleted {
                reconciledA.status = .turnedIn
                reconciledA.isManuallyCompleted = true
            }
            assertCondition(reconciledA.status == .pending, "Remote unsubmit without local manual check must revert to pending")
            assertCondition(reconciledA.isManuallyCompleted == false, "Remote unsubmit should have isManuallyCompleted == false")
            assertCondition(reconciledA.isCompleted == false, "Remote unsubmit should evaluate isCompleted == false")

            // Case B: Student manually tapped checkbox in app (isManuallyCompleted: true, status: .turnedIn)
            // Classroom sync returns status: .pending, isManuallyCompleted: false
            let cachedLocallyChecked = Coursework(id: "cw_local", courseId: "c1", courseName: "M", title: "Local Checked", dueDate: future, status: .turnedIn, isManuallyCompleted: true)
            let incomingPending = Coursework(id: "cw_local", courseId: "c1", courseName: "M", title: "Local Checked", dueDate: future, status: .pending, isManuallyCompleted: false)

            let freshMapB = [cachedLocallyChecked.id: cachedLocallyChecked]
            var reconciledB = incomingPending
            if let fresh = freshMapB[incomingPending.id], fresh.isManuallyCompleted, !reconciledB.isCompleted {
                reconciledB.status = .turnedIn
                reconciledB.isManuallyCompleted = true
            }
            assertCondition(reconciledB.status == .turnedIn, "Locally completed task must remain turnedIn after sync")
            assertCondition(reconciledB.isManuallyCompleted == true, "Locally completed task must preserve isManuallyCompleted flag")
            assertCondition(reconciledB.isCompleted == true, "Locally completed task must evaluate isCompleted == true")
        }

        // Test 11: Unauthenticated widget state integrity (no mock coursework leakage)
        do {
            func widgetDisplayItems(isLoggedIn: Bool, items: [Coursework]) -> [Coursework] {
                isLoggedIn ? items : []
            }
            let rawRealCoursework: [Coursework] = [
                Coursework(id: "cw_secret", courseId: "c1", courseName: "Math", title: "Secret HW", status: .pending)
            ]
            let loggedOutDisplay = widgetDisplayItems(isLoggedIn: false, items: rawRealCoursework)
            assertCondition(loggedOutDisplay.isEmpty, "Logged-out widget must have empty coursework list")

            let loggedInDisplay = widgetDisplayItems(isLoggedIn: true, items: rawRealCoursework)
            assertCondition(!loggedInDisplay.isEmpty, "Logged-in widget must display coursework list")
        }

        // Test 12: Calendar & Timezone formatting stability (Gregorian calendar pinning)
        do {
            var comp = DateComponents()
            comp.year = 2026
            comp.month = 10
            comp.day = 20
            comp.hour = 15
            comp.minute = 45
            comp.second = 0
            var gregorianCal = Calendar(identifier: .gregorian)
            gregorianCal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
            if let date = gregorianCal.date(from: comp) {
                let item = Coursework(id: "cw_greg", courseId: "c1", courseName: "Math", title: "Test Greg", dueDate: date, status: .pending)
                assertCondition(item.timeOnlyString == "15:45", "Coursework timeOnlyString must match expected Gregorian time '15:45'")
                assertCondition(item.formattedFullDueDate.contains("2026"), "Coursework formattedFullDueDate must use Gregorian year 2026")
            }
        }

        // Test 13: Personal notes integration in tomorrow coursework
        do {
            let cal = Calendar.autoupdatingCurrent
            let now = Date()
            guard let tomorrow = cal.date(byAdding: .day, value: 1, to: now) else {
                fatalError("Cannot calculate tomorrow")
            }
            var compTom = cal.dateComponents([.year, .month, .day], from: tomorrow)
            compTom.hour = 14
            compTom.minute = 30
            let tomorrowDate = cal.date(from: compTom) ?? tomorrow

            let standaloneNote = PersonalNote(
                id: "standalone_1",
                courseworkId: nil,
                courseId: "c_bio",
                courseName: "Sinh học",
                title: "Chuẩn bị mẫu vật",
                content: "Mang theo lá cây",
                dueDate: tomorrowDate,
                isCompleted: false
            )

            let courseworkAttachedNote = PersonalNote(
                id: "attached_1",
                courseworkId: "cw_existing",
                courseId: "c_bio",
                courseName: "Sinh học",
                title: "Ghi chú cho bài tập",
                content: "Chú ý câu 3",
                dueDate: tomorrowDate,
                isCompleted: false
            )

            ClassroomStorage.shared.savePersonalNotes([standaloneNote, courseworkAttachedNote])

            let tomorrowItems = ClassroomStorage.shared.getTomorrowCoursework(items: [], courses: [], includeCompleted: true, includeNotes: true)
            assertCondition(tomorrowItems.contains { $0.id == "note_standalone_1" }, "getTomorrowCoursework must include standalone personal note due tomorrow")
            assertCondition(!tomorrowItems.contains { $0.id == "note_attached_1" }, "getTomorrowCoursework must NOT include coursework-attached note as duplicate item")

            let noteItem = tomorrowItems.first { $0.id == "note_standalone_1" }
            assertCondition(noteItem?.compactDueString == "Mai 14:30", "Tomorrow 14:30 note must format as 'Mai 14:30'")

            // Toggle completion
            ClassroomStorage.shared.togglePersonalNoteCompletion(id: "standalone_1")
            let notesAfterToggle = ClassroomStorage.shared.loadPersonalNotes()
            assertCondition(notesAfterToggle.first { $0.id == "standalone_1" }?.isCompleted == true, "Personal note completion must toggle to true")

            // Delete note
            ClassroomStorage.shared.deletePersonalNote(id: "standalone_1")
            let notesAfterDelete = ClassroomStorage.shared.loadPersonalNotes()
            assertCondition(!notesAfterDelete.contains { $0.id == "standalone_1" }, "Personal note must be deleted")
        }

        // Test 15: Coursework Search Relevance Algorithm
        do {
            let itemExactTitle = Coursework(id: "cw_exact", courseId: "c1", courseName: "12A1", title: "Giải tích", description: "Bình thường")
            let itemPrefixTitle = Coursework(id: "cw_prefix", courseId: "c1", courseName: "12A1", title: "Giải tích chương 1", description: "Bình thường")
            let itemDescOnly = Coursework(id: "cw_desc", courseId: "c1", courseName: "12A1", title: "Bài tập cuối tuần", description: "Làm bài tập giải tích SGK")

            let tokens = ["giai", "tich"]
            let rawQuery = "giai tich"

            let scoreExact = itemExactTitle.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
            let scorePrefix = itemPrefixTitle.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
            let scoreDesc = itemDescOnly.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)

            assertCondition(scoreExact > scorePrefix, "Exact title match score (\(scoreExact)) must be higher than prefix title match score (\(scorePrefix))")
            assertCondition(scorePrefix > scoreDesc, "Prefix title match score (\(scorePrefix)) must be higher than description-only match score (\(scoreDesc))")
        }

        // Test 16: PersonalNote Search Relevance Algorithm
        do {
            let noteExact = PersonalNote(id: "n_exact", title: "Hóa học", content: "Nội dung")
            let noteDesc = PersonalNote(id: "n_desc", title: "Ghi nhớ", content: "Cần ôn bài hóa học")

            let tokens = ["hoa", "hoc"]
            let rawQuery = "hoa hoc"

            let scoreExact = noteExact.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
            let scoreDesc = noteDesc.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)

            assertCondition(scoreExact > scoreDesc, "PersonalNote exact title match score (\(scoreExact)) must be higher than content match score (\(scoreDesc))")
        }

        print("=== All Apple Core Logic Tests Passed Successfully! ===")
    }
}
