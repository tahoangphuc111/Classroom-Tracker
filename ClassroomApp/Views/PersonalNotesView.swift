import SwiftUI

public struct PersonalNotesView: View {
    public let notes: [PersonalNote]
    public let courses: [Course]
    public let searchText: String
    public let onToggleCompletion: (String) -> Void
    public let onSaveNote: (PersonalNote) -> Void
    public let onDeleteNote: (String) -> Void

    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedCourseId: String? = nil
    @State private var showCreateSheet: Bool = false
    @State private var noteToEdit: PersonalNote? = nil

    public enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "Tất cả"
        case pending = "Đang làm"
        case completed = "Đã xong"

        public var id: String { rawValue }
    }

    public init(
        notes: [PersonalNote],
        courses: [Course],
        searchText: String = "",
        onToggleCompletion: @escaping (String) -> Void,
        onSaveNote: @escaping (PersonalNote) -> Void,
        onDeleteNote: @escaping (String) -> Void
    ) {
        self.notes = notes
        self.courses = courses
        self.searchText = searchText
        self.onToggleCompletion = onToggleCompletion
        self.onSaveNote = onSaveNote
        self.onDeleteNote = onDeleteNote
    }

    private var filteredNotes: [PersonalNote] {
        var result = notes.filter { $0.courseworkId == nil }

        // Filter by status
        switch selectedStatusFilter {
        case .all:
            break
        case .pending:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        // Filter by course
        if let courseId = selectedCourseId {
            result = result.filter { $0.courseId == courseId }
        }

        // Filter by search text
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            let cleanQuery = query.normalizedForVietnameseSearch()
            let tokens = cleanQuery.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            result = result.filter { note in
                tokens.allSatisfy { note.searchIndex.contains($0) }
            }
        }

        // Sort: Pending first, then by due date or updatedAt
        return result.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            switch (first.dueDate, second.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 < d2 }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            return first.updatedAt > second.updatedAt
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            filterBarView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.platformControlBackground.opacity(0.4))

            Divider()

            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                notesListView
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateOrEditNoteSheet(
                existingNote: nil,
                courses: courses,
                onSave: { newNote in
                    onSaveNote(newNote)
                    showCreateSheet = false
                },
                onCancel: {
                    showCreateSheet = false
                }
            )
        }
        .sheet(item: $noteToEdit) { note in
            CreateOrEditNoteSheet(
                existingNote: note,
                courses: courses,
                onSave: { updatedNote in
                    onSaveNote(updatedNote)
                    noteToEdit = nil
                },
                onCancel: {
                    noteToEdit = nil
                }
            )
        }
    }

    private var filterBarView: some View {
        HStack(spacing: 12) {
            // Status Picker
            Picker("Trạng thái", selection: $selectedStatusFilter) {
                ForEach(StatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)

            // Course Filter Menu
            if !courses.isEmpty {
                Menu {
                    Button("Tất cả môn") {
                        selectedCourseId = nil
                    }
                    Divider()
                    ForEach(courses) { course in
                        Button(course.name) {
                            selectedCourseId = course.id
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedCourseId != nil ? (courses.first(where: { $0.id == selectedCourseId })?.name ?? "Môn học") : "Môn học")
                            .lineLimit(1)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.platformControlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Spacer()

            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Thêm ghi chú")
                        .font(.system(size: 13.5, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(SpringPressButtonStyle())
        }
    }

    private var notesListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredNotes) { note in
                    PersonalNoteRowCard(
                        note: note,
                        onToggle: { onToggleCompletion(note.id) },
                        onEdit: { noteToEdit = note },
                        onDelete: { onDeleteNote(note.id) }
                    )
                }
            }
            .padding(16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "square.and.pencil")
                .font(.system(size: 44))
                .foregroundStyle(Color.secondary.opacity(0.6))

            Text(searchText.isEmpty ? "Chưa có ghi chú nào" : "Không tìm thấy ghi chú phù hợp")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.platformTextPrimary)

            Text(searchText.isEmpty ? "Thêm ghi chú, to-do hoặc dặn dò cho việc học để theo dõi trong Báo bài." : "Thử tìm kiếm với từ khóa khác.")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.platformTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if searchText.isEmpty {
                Button {
                    showCreateSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Tạo ghi chú mới")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(SpringPressButtonStyle())
                .padding(.top, 6)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct PersonalNoteRowCard: View {
    let note: PersonalNote
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(note.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(note.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(note.isCompleted ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(note.isCompleted, color: Color.platformTextTertiary)

                    Spacer()

                    if let courseName = note.courseName, !courseName.isEmpty {
                        Text(courseName)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.blue)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }

                    if let dueDate = note.dueDate {
                        dueDateBadge(for: dueDate)
                    }
                }

                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.system(size: 14))
                        .foregroundStyle(note.isCompleted ? Color.platformTextTertiary : Color.platformTextSecondary)
                        .lineLimit(3)
                        .padding(.top, 1)
                }
            }

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Chỉnh sửa", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Xoá", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isHovered ? Color.platformCardHoverBorder : Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
        #if os(macOS)
        .onHover { isHovered = $0 }
        #endif
        .contextMenu {
            Button("Chỉnh sửa") { onEdit() }
            Button("Xoá", role: .destructive) { onDelete() }
        }
    }

    private func formattedDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func dueDateBadge(for date: Date) -> some View {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) {
            Text("Ngày mai")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else if calendar.isDateInToday(date) {
            Text("Hôm nay")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Text(formattedDateString(from: date))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

public struct CreateOrEditNoteSheet: View {
    public let existingNote: PersonalNote?
    public let courses: [Course]
    public let onSave: (PersonalNote) -> Void
    public let onCancel: () -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCourseId: String = ""
    @State private var selectedDueDateMode: DueDateMode = .none
    @State private var customDueDate: Date = Date()

    public enum DueDateMode: String, CaseIterable, Identifiable {
        case none = "Không đặt hạn"
        case today = "Hôm nay"
        case tomorrow = "Ngày mai"
        case custom = "Chọn ngày"

        public var id: String { rawValue }
    }

    public init(
        existingNote: PersonalNote?,
        courses: [Course],
        onSave: @escaping (PersonalNote) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingNote = existingNote
        self.courses = courses
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Nội dung ghi chú") {
                    TextField("Tiêu đề (ví dụ: Mua dụng cụ học tập)", text: $title)
                        .font(.system(size: 15, weight: .medium))

                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .font(.system(size: 14))
                }

                Section("Liên kết môn học") {
                    Picker("Môn học", selection: $selectedCourseId) {
                        Text("Không gắn môn").tag("")
                        ForEach(courses) { course in
                            Text(course.name).tag(course.id)
                        }
                    }
                }

                Section("Thời hạn cần làm (Báo bài)") {
                    Picker("Hạn nộp", selection: $selectedDueDateMode) {
                        ForEach(DueDateMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedDueDateMode == .custom {
                        DatePicker("Chọn ngày", selection: $customDueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(existingNote == nil ? "Ghi chú mới" : "Chỉnh sửa ghi chú")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing = existingNote {
                    title = existing.title
                    content = existing.content
                    selectedCourseId = existing.courseId ?? ""
                    if let due = existing.dueDate {
                        let cal = Calendar.current
                        if cal.isDateInToday(due) {
                            selectedDueDateMode = .today
                        } else if cal.isDateInTomorrow(due) {
                            selectedDueDateMode = .tomorrow
                        } else {
                            selectedDueDateMode = .custom
                            customDueDate = due
                        }
                    } else {
                        selectedDueDateMode = .none
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 420)
        #endif
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let cal = Calendar.current
        let computedDueDate: Date?
        switch selectedDueDateMode {
        case .none:
            computedDueDate = nil
        case .today:
            computedDueDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        case .tomorrow:
            if let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) {
                computedDueDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow)
            } else {
                computedDueDate = nil
            }
        case .custom:
            computedDueDate = customDueDate
        }

        let selectedCourse = courses.first(where: { $0.id == selectedCourseId })

        let finalNote = PersonalNote(
            id: existingNote?.id ?? UUID().uuidString,
            courseworkId: existingNote?.courseworkId,
            courseId: selectedCourse?.id,
            courseName: selectedCourse?.name,
            title: trimmedTitle,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: computedDueDate,
            isCompleted: existingNote?.isCompleted ?? false,
            createdAt: existingNote?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(finalNote)
    }
}
