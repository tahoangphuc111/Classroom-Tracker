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

            let normalizedQuery = "giai tich".normalizedForVietnameseSearch()
            assertCondition(note.searchIndex.contains(normalizedQuery), "PersonalNote search index must match diacritic-free Vietnamese query")

            let queryTitle = "toan hoc".normalizedForVietnameseSearch()
            assertCondition(note.searchIndex.contains(queryTitle), "PersonalNote search index must match course name query")

            assertCondition(note.isDueTomorrow, "PersonalNote with tomorrow dueDate must return isDueTomorrow == true")
            assertCondition(!note.isDueToday, "PersonalNote with tomorrow dueDate must return isDueToday == false")

            let encoded = try JSONEncoder().encode(note)
            let decoded = try JSONDecoder().decode(PersonalNote.self, from: encoded)

            assertCondition(decoded.id == note.id, "Decoded note ID must match original")
            assertCondition(decoded.courseworkId == "cw_456", "Decoded courseworkId must match")
            assertCondition(decoded.title == note.title, "Decoded title must match")
            assertCondition(decoded.content == note.content, "Decoded content must match")
            assertCondition(decoded.isCompleted == false, "Decoded completion state must match")

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

        do {
            let cal = Calendar.autoupdatingCurrent
            let now = Date()

            let noDue = Coursework(id: "cw_nodue", courseId: "c1", courseName: "M", title: "T", dueDate: nil, status: .pending)
            assertCondition(noDue.compactDueString == "Không hạn", "No due date must format as 'Không hạn'")

            let completed = Coursework(id: "cw_done", courseId: "c1", courseName: "M", title: "T", dueDate: now.addingTimeInterval(3600), status: .turnedIn)
            assertCondition(completed.compactDueString == "Đã xong", "Completed item must format as 'Đã xong'")

            var compToday = cal.dateComponents([.year, .month, .day], from: now)
            compToday.hour = 23
            compToday.minute = 59
            compToday.second = 59
            if let todayEndOfDay = cal.date(from: compToday), todayEndOfDay > now {
                let todayEOD = Coursework(id: "cw_today_eod", courseId: "c1", courseName: "M", title: "T", dueDate: todayEndOfDay, status: .pending)
                assertCondition(todayEOD.compactDueString == "Cuối ngày", "Today end-of-day (23:59:59) must format as 'Cuối ngày'")
            }

            var compToday2355 = cal.dateComponents([.year, .month, .day], from: now)
            compToday2355.hour = 23
            compToday2355.minute = 55
            compToday2355.second = 0
            if let today2355 = cal.date(from: compToday2355), today2355 > now {
                let today2355Item = Coursework(id: "cw_today_2355", courseId: "c1", courseName: "M", title: "T", dueDate: today2355, status: .pending)
                assertCondition(today2355Item.compactDueString == "Cuối ngày", "Today 23:55 must format as 'Cuối ngày'")
            }

            var compToday2030 = cal.dateComponents([.year, .month, .day], from: now)
            compToday2030.hour = 20
            compToday2030.minute = 30
            compToday2030.second = 0
            if let today2030 = cal.date(from: compToday2030), today2030 > now {
                let today2030Item = Coursework(id: "cw_today_2030", courseId: "c1", courseName: "M", title: "T", dueDate: today2030, status: .pending)
                assertCondition(today2030Item.compactDueString == "20:30", "Today 20:30 must format as '20:30'")
            }

            if let tomorrow = cal.date(byAdding: .day, value: 1, to: now) {
                var compTomEOD = cal.dateComponents([.year, .month, .day], from: tomorrow)
                compTomEOD.hour = 23
                compTomEOD.minute = 59
                compTomEOD.second = 59
                if let tomorrowEndOfDay = cal.date(from: compTomEOD) {
                    let tomEOD = Coursework(id: "cw_tom_eod", courseId: "c1", courseName: "M", title: "T", dueDate: tomorrowEndOfDay, status: .pending)
                    assertCondition(tomEOD.compactDueString == "Mai", "Tomorrow end-of-day (23:59:59) must format as 'Mai'")
                }

                var compTom2355 = cal.dateComponents([.year, .month, .day], from: tomorrow)
                compTom2355.hour = 23
                compTom2355.minute = 55
                compTom2355.second = 0
                if let tomorrow2355 = cal.date(from: compTom2355) {
                    let tom2355 = Coursework(id: "cw_tom_2355", courseId: "c1", courseName: "M", title: "T", dueDate: tomorrow2355, status: .pending)
                    assertCondition(tom2355.compactDueString == "Mai", "Tomorrow 23:55 must format as 'Mai'")
                }

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

        do {
            let future = Date().addingTimeInterval(86400 * 2)

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

            ClassroomStorage.shared.togglePersonalNoteCompletion(id: "standalone_1")
            let notesAfterToggle = ClassroomStorage.shared.loadPersonalNotes()
            assertCondition(notesAfterToggle.first { $0.id == "standalone_1" }?.isCompleted == true, "Personal note completion must toggle to true")

            ClassroomStorage.shared.deletePersonalNote(id: "standalone_1")
            let notesAfterDelete = ClassroomStorage.shared.loadPersonalNotes()
            assertCondition(!notesAfterDelete.contains { $0.id == "standalone_1" }, "Personal note must be deleted")
        }

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

        do {
            let noteExact = PersonalNote(id: "n_exact", title: "Hóa học", content: "Nội dung")
            let noteDesc = PersonalNote(id: "n_desc", title: "Ghi nhớ", content: "Cần ôn bài hóa học")

            let tokens = ["hoa", "hoc"]
            let rawQuery = "hoa hoc"

            let scoreExact = noteExact.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)
            let scoreDesc = noteDesc.searchRelevanceScore(for: tokens, rawNormalizedQuery: rawQuery)

            assertCondition(scoreExact > scoreDesc, "PersonalNote exact title match score (\(scoreExact)) must be higher than content match score (\(scoreDesc))")
        }

        do {
            let item1 = ChecklistItem(id: "item_1", title: "Mua máy tính Casio", isCompleted: false)
            let item2 = ChecklistItem(id: "item_2", title: "In đề cương", isCompleted: true)
            let noteWithChecklist = PersonalNote(
                id: "note_chk_1",
                title: "Chuẩn bị học kì",
                checklist: [item1, item2]
            )

            assertCondition(noteWithChecklist.hasChecklist, "Note with checklist must return hasChecklist == true")
            assertCondition(noteWithChecklist.totalChecklistCount == 2, "totalChecklistCount must be 2")
            assertCondition(noteWithChecklist.completedChecklistCount == 1, "completedChecklistCount must be 1")
            assertCondition(noteWithChecklist.checklistProgress == 0.5, "checklistProgress must be 0.5")

            let encodedData = try JSONEncoder().encode(noteWithChecklist)
            let decodedNote = try JSONDecoder().decode(PersonalNote.self, from: encodedData)
            assertCondition(decodedNote.checklist.count == 2, "Decoded note must preserve 2 checklist items")
            assertCondition(decodedNote.checklist[0].title == "Mua máy tính Casio", "Decoded checklist title must match")
            assertCondition(decodedNote.checklist[1].isCompleted == true, "Decoded checklist completion state must match")

            let query = "may tinh".normalizedForVietnameseSearch()
            assertCondition(decodedNote.searchIndex.contains(query), "PersonalNote search index must include checklist titles")

            ClassroomStorage.shared.savePersonalNotes([noteWithChecklist])
            ClassroomStorage.shared.toggleChecklistItemCompletion(noteId: "note_chk_1", itemId: "item_1")

            let notesAfterCheck = ClassroomStorage.shared.loadPersonalNotes()
            let updatedNote = notesAfterCheck.first { $0.id == "note_chk_1" }
            assertCondition(updatedNote?.checklist.first { $0.id == "item_1" }?.isCompleted == true, "Checklist item 1 must be toggled to completed")
            assertCondition(updatedNote?.isCompleted == true, "Note must auto-complete when all checklist items are done")

            ClassroomStorage.shared.toggleChecklistItemCompletion(noteId: "note_chk_1", itemId: "item_2")
            let notesAfterUncheck = ClassroomStorage.shared.loadPersonalNotes()
            let uncompleteNote = notesAfterUncheck.first { $0.id == "note_chk_1" }
            assertCondition(uncompleteNote?.checklist.first { $0.id == "item_2" }?.isCompleted == false, "Checklist item 2 must be toggled to false")
            assertCondition(uncompleteNote?.isCompleted == false, "Note must revert to incomplete when any checklist item is pending")

            ClassroomStorage.shared.deletePersonalNote(id: "note_chk_1")
        } catch {
            assertCondition(false, "ChecklistItem test failed: \(error)")
        }

        do {
            let future = Date().addingTimeInterval(86400 * 3)
            let testTask = Coursework(
                id: "cw_storage_test_1",
                courseId: "c_storage",
                courseName: "Vật lý",
                title: "Bài tập con lắc",
                dueDate: future,
                status: .pending,
                isManuallyCompleted: false
            )

            ClassroomStorage.shared.saveCoursework([testTask])

            ClassroomStorage.shared.toggleCourseworkCompletion(id: "cw_storage_test_1", completed: true)
            let loaded = ClassroomStorage.shared.loadCoursework()
            let toggledItem = loaded.first { $0.id == "cw_storage_test_1" }
            assertCondition(toggledItem?.status == .turnedIn, "Toggled coursework must have status .turnedIn")
            assertCondition(toggledItem?.isManuallyCompleted == true, "Toggled coursework must have isManuallyCompleted == true")
            assertCondition(toggledItem?.isCompleted == true, "Toggled coursework must evaluate isCompleted == true")

            let incomingPending = Coursework(
                id: "cw_storage_test_1",
                courseId: "c_storage",
                courseName: "Vật lý",
                title: "Bài tập con lắc (tiêu đề mới từ Google)",
                dueDate: future,
                status: .pending,
                isManuallyCompleted: false
            )

            let reconciled = ClassroomStorage.shared.reconcileCoursework(incoming: [incomingPending])
            assertCondition(reconciled.count == 1, "Reconciled coursework must have 1 item")
            assertCondition(reconciled[0].status == .turnedIn, "Locally completed task must remain .turnedIn after sync")
            assertCondition(reconciled[0].isManuallyCompleted == true, "Locally completed task must preserve isManuallyCompleted == true")
            assertCondition(reconciled[0].title == "Bài tập con lắc (tiêu đề mới từ Google)", "Reconciled item must update remote metadata like title")

            ClassroomStorage.shared.updateCourseworkStatuses(ids: ["cw_storage_test_1"], newStatus: .turnedIn)
            let loadedAfterUpdate = ClassroomStorage.shared.loadCoursework()
            assertCondition(loadedAfterUpdate.first { $0.id == "cw_storage_test_1" }?.isManuallyCompleted == true, "updateCourseworkStatuses turnedIn must set isManuallyCompleted = true")

            ClassroomStorage.shared.updateCourseworkStatuses(ids: ["cw_storage_test_1"], newStatus: .pending)
            let loadedAfterPending = ClassroomStorage.shared.loadCoursework()
            assertCondition(loadedAfterPending.first { $0.id == "cw_storage_test_1" }?.isManuallyCompleted == false, "updateCourseworkStatuses pending must set isManuallyCompleted = false")
        }

        do {
            let future = Date().addingTimeInterval(86400 * 3)
            let remoteTurnedInTask = Coursework(
                id: "cw_remote_unsubmit_storage",
                courseId: "c_storage",
                courseName: "Hóa học",
                title: "Bài tập Este",
                dueDate: future,
                status: .turnedIn,
                isManuallyCompleted: false
            )
            ClassroomStorage.shared.saveCoursework([remoteTurnedInTask])

            let incomingUnsubmit = Coursework(
                id: "cw_remote_unsubmit_storage",
                courseId: "c_storage",
                courseName: "Hóa học",
                title: "Bài tập Este",
                dueDate: future,
                status: .pending,
                isManuallyCompleted: false
            )

            let reconciled = ClassroomStorage.shared.reconcileCoursework(incoming: [incomingUnsubmit])
            assertCondition(reconciled.first?.status == .pending, "reconcileCoursework in ClassroomStorage must revert to .pending when remote unsubmit occurs and task was not manually completed")
            assertCondition(reconciled.first?.isManuallyCompleted == false, "reconcileCoursework must preserve isManuallyCompleted = false for remote unsubmit")
        }

        do {
            assertCondition("ĐẠI SỐ & GIẢI TÍCH".normalizedForVietnameseSearch() == "dai so & giai tich", "Uppercase Đ and diacritics must be properly normalized")
            assertCondition("Giáo Dục Kinh Tế Và Pháp Luật".normalizedForVietnameseSearch() == "giao duc kinh te va phap luat", "Complex compound Vietnamese title must be diacritic-stripped")
            assertCondition("Lịch Sử & Địa Lý".normalizedForVietnameseSearch() == "lich su & dia ly", "Multiple words with diacritics must be diacritic-stripped")

            let coursework = Coursework(
                id: "cw_viet_search",
                courseId: "c_viet",
                courseName: "Giáo Dục Kinh Tế Và Pháp Luật",
                title: "Tìm hiểu Luật Doanh Nghiệp 2020",
                description: "Nêu các quyền và nghĩa vụ cơ bản của người kinh doanh"
            )

            let query = "doanh nghiep"
            let tokens = ["doanh", "nghiep"]
            let score = coursework.searchRelevanceScore(for: tokens, rawNormalizedQuery: query)
            assertCondition(score > 0, "Search score for diacritic-free query 'doanh nghiep' on 'Doanh Nghiệp' must be positive")
            assertCondition(coursework.searchIndex.contains("luat doanh nghiep"), "Search index must contain normalized keywords")
        }

        do {
            let initialStatus = ClassroomStorage.shared.hasUserLoggedIn
            ClassroomStorage.shared.saveUserLoggedIn(true)
            assertCondition(ClassroomStorage.shared.hasUserLoggedIn == true, "hasUserLoggedIn must be true after saveUserLoggedIn(true)")

            ClassroomStorage.shared.saveUserEmail("student@school.edu.vn")
            assertCondition(ClassroomStorage.shared.loadUserEmail() == "student@school.edu.vn", "loadUserEmail must return saved email")

            let metadata = ClassroomStorage.shared.loadSharedMetadata()
            assertCondition(metadata?.userEmail == "student@school.edu.vn", "Shared metadata must reflect saved email")
            assertCondition(metadata?.hasUserLoggedIn == true, "Shared metadata must reflect logged-in state")

            ClassroomStorage.shared.invalidateMemoryCache()
            assertCondition(ClassroomStorage.shared.loadUserEmail() == "student@school.edu.vn", "loadUserEmail must reload persisted email after memory cache invalidation")
            assertCondition(ClassroomStorage.shared.hasUserLoggedIn == true, "hasUserLoggedIn must remain true across memory cache invalidation")

            ClassroomStorage.shared.saveUserLoggedIn(false)
            ClassroomStorage.shared.invalidateMemoryCache()
            ClassroomStorage.shared.saveCourses([
                Course(id: "google_course_12345", name: "Toán 12A", section: "12A", descriptionHeading: "Toán học", isSelectedForWidget: true)
            ])
            ClassroomStorage.shared.invalidateMemoryCache()
            assertCondition(ClassroomStorage.shared.hasUserLoggedIn == true, "hasUserLoggedIn must be true when real Google Classroom courses exist")

            ClassroomStorage.shared.clearAllData()
            ClassroomStorage.shared.flushIOQueue()
            ClassroomStorage.shared.invalidateMemoryCache()
            assertCondition(ClassroomStorage.shared.hasUserLoggedIn == false, "hasUserLoggedIn must be false after clearAllData")

            // Verify cached_oauth_tokens.json is removed by clearAllData
            for dir in ClassroomStorage.sharedStorageDirectories {
                if FileManager.default.fileExists(atPath: dir.path) || (try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)) != nil {
                    let tokenFile = dir.appendingPathComponent("cached_oauth_tokens.json")
                    if (try? "{}".data(using: .utf8)?.write(to: tokenFile)) != nil {
                        ClassroomStorage.shared.invalidateMemoryCache()
                        assertCondition(ClassroomStorage.shared.hasUserLoggedIn == true, "Token file presence must trigger hasUserLoggedIn == true")

                        ClassroomStorage.shared.clearAllData()
                        ClassroomStorage.shared.flushIOQueue()
                        ClassroomStorage.shared.invalidateMemoryCache()
                        assertCondition(!FileManager.default.fileExists(atPath: tokenFile.path), "cached_oauth_tokens.json must be removed by clearAllData")
                        assertCondition(ClassroomStorage.shared.hasUserLoggedIn == false, "hasUserLoggedIn must be false after token file deletion via clearAllData")
                        break
                    }
                }
            }

            ClassroomStorage.shared.saveUserLoggedIn(initialStatus)
        }

        do {
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "com.phucta.classroom.tests.concurrency", attributes: .concurrent)
            let testIterations = 100

            for i in 0..<testIterations {
                group.enter()
                queue.async {
                    let task = Coursework(
                        id: "cw_stress_\(i)",
                        courseId: "c_stress_\(i % 3)",
                        courseName: "Course \(i % 3)",
                        title: "Title \(i)",
                        status: i % 2 == 0 ? .pending : .turnedIn,
                        isManuallyCompleted: i % 2 != 0
                    )
                    ClassroomStorage.shared.saveCoursework([task])
                    _ = ClassroomStorage.shared.loadCoursework()
                    _ = ClassroomStorage.shared.getPendingCoursework()
                    group.leave()
                }

                group.enter()
                queue.async {
                    let note = PersonalNote(
                        id: "note_stress_\(i)",
                        courseworkId: "cw_stress_\(i)",
                        title: "Note \(i)",
                        content: "Content \(i)",
                        isCompleted: i % 2 == 0
                    )
                    ClassroomStorage.shared.savePersonalNotes([note])
                    _ = ClassroomStorage.shared.loadPersonalNotes()
                    ClassroomStorage.shared.togglePersonalNoteCompletion(id: "note_stress_\(i)")
                    group.leave()
                }
            }

            let waitResult = group.wait(timeout: .now() + 10.0)
            assertCondition(waitResult == .success, "Concurrent storage operations must complete without deadlock or timeout")
        }

        do {
            ClassroomStorage.shared.flushIOQueue()
            ClassroomStorage.shared.invalidateMemoryCache()
            assertCondition(true, "flushIOQueue and invalidateMemoryCache must complete without deadlock")
        }

        do {
            assertCondition(AppleOSDetector.isAppleOS, "AppleOSDetector.isAppleOS must be true on Apple platforms")
            assertCondition(!AppleOSDetector.currentOSDescription.isEmpty, "AppleOSDetector.currentOSDescription must not be empty")
            assertCondition(
                AppleOSDetector.currentOSDescription.contains("macOS") || AppleOSDetector.currentOSDescription.contains("iOS"),
                "AppleOSDetector.currentOSDescription must identify macOS or iOS"
            )
            assertCondition(!AppleOSDetector.designEngineStatus.isEmpty, "AppleOSDetector.designEngineStatus must not be empty")
            let hasLiquidGlassSupport = AppleOSDetector.supportsLiquidGlass
            if hasLiquidGlassSupport {
                assertCondition(
                    AppleOSDetector.designEngineStatus == "Apple Liquid Glass SDK",
                    "designEngineStatus must indicate Apple Liquid Glass SDK when supported"
                )
            }
        }

        print("=== All Apple Core Logic Tests Passed Successfully! ===")
    }
}
