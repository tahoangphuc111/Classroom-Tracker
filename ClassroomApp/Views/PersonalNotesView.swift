import SwiftUI

public struct PersonalNotesView: View {
    public let notes: [PersonalNote]
    public let courses: [Course]
    public let searchText: String
    public let onToggleCompletion: (String) -> Void
    public let onToggleChecklistItem: ((String, String) -> Void)?
    public let onSaveNote: (PersonalNote) -> Void
    public let onDeleteNote: (String) -> Void

    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedCourseId: String? = nil
    @State private var activeSheet: ActiveNoteSheet? = nil
    @State private var emptyAppeared: Bool = false

    // Quick To-Do state
    @State private var quickTodoTitle: String = ""
    @State private var quickTodoDue: DueDateMode = .none
    @State private var quickTodoCourseId: String? = nil

    public enum DueDateMode: String, CaseIterable, Identifiable {
        case none = "Không hạn"
        case today = "Hôm nay"
        case tomorrow = "Ngày mai"
        case custom = "Chọn ngày"

        public var id: String { rawValue }
    }

    public enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "Tất cả"
        case pending = "Đang làm"
        case completed = "Đã xong"

        public var id: String { rawValue }
    }

    public enum ActiveNoteSheet: Identifiable {
        case create
        case edit(PersonalNote)

        public var id: String {
            switch self {
            case .create: return "create"
            case .edit(let note): return "edit_\(note.id)"
            }
        }
    }

    public init(
        notes: [PersonalNote],
        courses: [Course],
        searchText: String = "",
        onToggleCompletion: @escaping (String) -> Void,
        onToggleChecklistItem: ((String, String) -> Void)? = nil,
        onSaveNote: @escaping (PersonalNote) -> Void,
        onDeleteNote: @escaping (String) -> Void
    ) {
        self.notes = notes
        self.courses = courses
        self.searchText = searchText
        self.onToggleCompletion = onToggleCompletion
        self.onToggleChecklistItem = onToggleChecklistItem
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
            if !tokens.isEmpty {
                result = result.filter { note in
                    tokens.allSatisfy { note.searchIndex.contains($0) }
                }
                return result.sorted { first, second in
                    let score1 = first.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)
                    let score2 = second.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)
                    if score1 != score2 {
                        return score1 > score2
                    }
                    if first.isCompleted != second.isCompleted {
                        return !first.isCompleted
                    }
                    return first.updatedAt > second.updatedAt
                }
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

            quickTodoBar
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .background(Color.platformControlBackground.opacity(0.4))

            Divider()

            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                notesListView
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedStatusFilter)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedCourseId)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                CreateOrEditNoteSheet(
                    existingNote: nil,
                    courses: courses,
                    onSave: { newNote in
                        onSaveNote(newNote)
                        activeSheet = nil
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            case .edit(let note):
                CreateOrEditNoteSheet(
                    existingNote: note,
                    courses: courses,
                    onSave: { updatedNote in
                        onSaveNote(updatedNote)
                        activeSheet = nil
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenCreateNoteSheet"))) { _ in
            activeSheet = .create
        }
    }

    private var filterBarView: some View {
        ViewThatFits(in: .horizontal) {
            wideFilterBar
            compactFilterBar
        }
    }

    private var statusPicker: some View {
        Picker("Trạng thái", selection: $selectedStatusFilter) {
            ForEach(StatusFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var courseFilterMenu: some View {
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
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 13, weight: .semibold))
                    Text(selectedCourseId != nil ? (courses.first(where: { $0.id == selectedCourseId })?.name ?? "Môn học") : "Môn học")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.platformCardBorder, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private func addNoteButton(compact: Bool = false) -> some View {
        Button {
            activeSheet = .create
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                if !compact {
                    Text("Thêm ghi chú")
                        .font(.system(size: 13.5, weight: .semibold))
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .accessibilityLabel("Thêm ghi chú")
    }

    private var wideFilterBar: some View {
        HStack(spacing: 12) {
            statusPicker
                .frame(width: 230)

            courseFilterMenu

            Spacer()

            addNoteButton()
        }
    }

    private var compactFilterBar: some View {
        VStack(spacing: 8) {
            statusPicker
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                courseFilterMenu

                Spacer()

                ViewThatFits(in: .horizontal) {
                    addNoteButton(compact: false)
                    addNoteButton(compact: true)
                }
            }
        }
    }

    private var quickTodoBar: some View {
        ViewThatFits(in: .horizontal) {
            singleLineQuickTodoBar
            compactStackedQuickTodoBar
        }
    }

    private var singleLineQuickTodoBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.blue)

            TextField("Thêm việc cần làm nhanh...", text: $quickTodoTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
                .submitLabel(.done)
                .onSubmit {
                    submitQuickTodo()
                }

            if !quickTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                quickTodoDueDateMenu
                quickTodoCourseMenu
            }

            quickTodoSubmitButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.platformControlBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.platformCardBorder, lineWidth: 1)
        )
    }

    private var compactStackedQuickTodoBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.blue)

                TextField("Thêm việc cần làm nhanh...", text: $quickTodoTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5))
                    .submitLabel(.done)
                    .onSubmit {
                        submitQuickTodo()
                    }

                quickTodoSubmitButton
            }

            if !quickTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack(spacing: 6) {
                    quickTodoDueDateMenu
                    quickTodoCourseMenu
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.platformControlBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.platformCardBorder, lineWidth: 1)
        )
    }

    private var quickTodoDueDateMenu: some View {
        Menu {
            Button("Không đặt hạn") { quickTodoDue = .none }
            Button("Hôm nay") { quickTodoDue = .today }
            Button("Ngày mai") { quickTodoDue = .tomorrow }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10.5))
                Text(quickTodoDue.rawValue)
                    .font(.system(size: 11.5, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7.5, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.platformSubtleFill)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    @ViewBuilder
    private var quickTodoCourseMenu: some View {
        if !courses.isEmpty {
            Menu {
                Button("Không gắn môn") { quickTodoCourseId = nil }
                Divider()
                ForEach(courses) { course in
                    Button(course.name) { quickTodoCourseId = course.id }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "book")
                        .font(.system(size: 10.5))
                    Text(quickTodoCourseId != nil ? (courses.first(where: { $0.id == quickTodoCourseId })?.name ?? "Môn") : "Môn")
                        .font(.system(size: 11.5, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.platformSubtleFill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var quickTodoSubmitButton: some View {
        Button {
            submitQuickTodo()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(quickTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.35) : Color.blue)
                #if os(iOS)
                .frame(width: 36, height: 36)
                #else
                .frame(width: 28, height: 28)
                #endif
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(quickTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        .accessibilityLabel("Tạo việc cần làm")
    }

    private func submitQuickTodo() {
        let trimmed = quickTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let cal = Calendar.current
        let computedDue: Date?
        switch quickTodoDue {
        case .none:
            computedDue = nil
        case .today:
            computedDue = cal.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        case .tomorrow:
            if let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) {
                computedDue = cal.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow)
            } else {
                computedDue = nil
            }
        case .custom:
            computedDue = nil
        }

        let selectedCourse = courses.first(where: { $0.id == quickTodoCourseId })

        let newNote = PersonalNote(
            courseId: selectedCourse?.id,
            courseName: selectedCourse?.name,
            title: trimmed,
            content: "",
            checklist: [],
            dueDate: computedDue,
            isCompleted: false
        )
        onSaveNote(newNote)
        quickTodoTitle = ""
        quickTodoCourseId = nil
        quickTodoDue = .none
    }

    private var notesListView: some View {
        ScrollView {
            #if os(macOS)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 440), spacing: 12, alignment: .top)], spacing: 12) {
                ForEach(filteredNotes) { note in
                    PersonalNoteRowCard(
                        note: note,
                        onToggle: { onToggleCompletion(note.id) },
                        onToggleChecklistItem: { noteId, itemId in
                            if let toggle = onToggleChecklistItem {
                                toggle(noteId, itemId)
                            } else {
                                toggleLocalChecklistItem(note: note, itemId: itemId)
                            }
                        },
                        onEdit: { activeSheet = .edit(note) },
                        onDelete: { onDeleteNote(note.id) }
                    )
                    .equatable()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.32, dampingFraction: 0.8), value: filteredNotes.map(\.id))
            #else
            LazyVStack(spacing: 10) {
                ForEach(filteredNotes) { note in
                    PersonalNoteRowCard(
                        note: note,
                        onToggle: { onToggleCompletion(note.id) },
                        onToggleChecklistItem: { noteId, itemId in
                            if let toggle = onToggleChecklistItem {
                                toggle(noteId, itemId)
                            } else {
                                toggleLocalChecklistItem(note: note, itemId: itemId)
                            }
                        },
                        onEdit: { activeSheet = .edit(note) },
                        onDelete: { onDeleteNote(note.id) }
                    )
                    .equatable()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.32, dampingFraction: 0.8), value: filteredNotes.map(\.id))
            #endif
        }
    }

    private func toggleLocalChecklistItem(note: PersonalNote, itemId: String) {
        var updated = note
        guard let idx = updated.checklist.firstIndex(where: { $0.id == itemId }) else { return }
        updated.checklist[idx].isCompleted.toggle()
        if !updated.checklist.isEmpty && updated.checklist.allSatisfy({ $0.isCompleted }) {
            updated.isCompleted = true
        } else if updated.checklist.contains(where: { !$0.isCompleted }) && updated.isCompleted {
            updated.isCompleted = false
        }
        onSaveNote(updated)
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .scaleEffect(emptyAppeared ? 1.0 : 0.88)

            Text(searchText.isEmpty ? "Chưa có việc cần làm hay ghi chú nào" : "Không tìm thấy ghi chú phù hợp")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.platformTextPrimary)

            Text(searchText.isEmpty ? "Thêm việc cần làm (to-do), checklist hoặc dặn dò cho việc học để theo dõi trong Báo bài." : "Thử tìm kiếm với từ khóa khác.")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.platformTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            if searchText.isEmpty {
                Button {
                    activeSheet = .create
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Tạo ghi chú / to-do mới")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 6)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .opacity(emptyAppeared ? 1.0 : 0.0)
        .scaleEffect(emptyAppeared ? 1.0 : 0.95)
        .offset(y: emptyAppeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                emptyAppeared = true
            }
        }
    }
}

private struct PersonalNoteRowCard: View, Equatable {
    let note: PersonalNote
    let onToggle: () -> Void
    let onToggleChecklistItem: (String, String) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    static func == (lhs: PersonalNoteRowCard, rhs: PersonalNoteRowCard) -> Bool {
        lhs.note == rhs.note
    }

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Main checkmark button
            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                    checkmarkBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                        checkmarkBounce = false
                    }
                }
                onToggle()
            } label: {
                ZStack {
                    if note.isCompleted {
                        if #available(macOS 14.0, iOS 17.0, *) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.green)
                                .scaleEffect(checkmarkBounce ? 1.28 : 1.0)
                                .symbolEffect(.bounce, value: note.isCompleted)
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.green)
                                .scaleEffect(checkmarkBounce ? 1.28 : 1.0)
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .scaleEffect(checkmarkBounce ? 0.9 : 1.0)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                #if os(iOS)
                .frame(width: 38, height: 38)
                #else
                .frame(width: 28, height: 28)
                #endif
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Center content area
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(note.title)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(note.isCompleted ? Color.platformTextSecondary : Color.platformTextPrimary)
                    .strikethrough(note.isCompleted, color: Color.platformTextTertiary)
                    .opacity(note.isCompleted ? 0.72 : 1.0)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: note.isCompleted)

                // Course and due date badges
                if (note.courseName != nil && !note.courseName!.isEmpty) || note.dueDate != nil {
                    HStack(spacing: 6) {
                        if let courseName = note.courseName, !courseName.isEmpty {
                            Text(courseName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .lineLimit(1)
                        }

                        if let dueDate = note.dueDate {
                            dueDateBadge(for: dueDate)
                        }
                    }
                }

                // Checklist count progress pill (if note has checklist)
                if note.hasChecklist {
                    HStack(spacing: 6) {
                        let doneCount = note.completedChecklistCount
                        let totalCount = note.totalChecklistCount
                        let isAllDone = doneCount == totalCount && totalCount > 0

                        HStack(spacing: 4) {
                            Image(systemName: isAllDone ? "checkmark.circle.fill" : "checklist")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(doneCount)/\(totalCount) việc")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundStyle(isAllDone ? Color.green : Color.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((isAllDone ? Color.green : Color.blue).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                        if totalCount > 1 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(isAllDone ? Color.green : Color.blue)
                                        .frame(
                                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(max(0.0, min(1.0, note.checklistProgress))))),
                                            height: 4
                                        )
                                }
                            }
                            .frame(height: 4)
                            .frame(minWidth: 40, maxWidth: 120)
                        }
                    }
                    .padding(.top, 2)

                    // Interactive Checklist items preview
                    VStack(alignment: .leading, spacing: 4.5) {
                        ForEach(note.checklist.prefix(4)) { item in
                            HStack(spacing: 7) {
                                Button {
                                    onToggleChecklistItem(note.id, item.id)
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(item.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                                        .frame(width: 16, height: 16)
                                }
                                .buttonStyle(.plain)
                                #if os(iOS)
                                .frame(width: 28, height: 28)
                                #else
                                .frame(width: 22, height: 22)
                                #endif
                                .contentShape(Rectangle())

                                Text(item.title)
                                    .font(.system(size: 13))
                                    .foregroundStyle(item.isCompleted ? Color.platformTextTertiary : Color.platformTextSecondary)
                                    .strikethrough(item.isCompleted, color: Color.platformTextTertiary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        if note.checklist.count > 4 {
                            Text("+ \(note.checklist.count - 4) mục khác...")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Color.secondary)
                                .padding(.leading, 29)
                        }
                    }
                    .padding(.top, 2)
                }

                // Multiline content (if any)
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.system(size: 13.5))
                        .foregroundStyle(note.isCompleted ? Color.platformTextTertiary : Color.platformTextSecondary)
                        .opacity(note.isCompleted ? 0.7 : 1.0)
                        .lineLimit(2)
                        .padding(.top, 1)
                        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: note.isCompleted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }

            // Menu actions
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
                    #if os(iOS)
                    .frame(width: 38, height: 38)
                    #else
                    .frame(width: 28, height: 28)
                    #endif
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isHovered ? Color.platformCardHoverBorder : Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.03 : 0.015), radius: 3, x: 0, y: 1)
        #if os(macOS)
        .onHover { isHovered = $0 }
        #endif
        .animation(.easeInOut(duration: 0.12), value: isHovered)
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
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else if calendar.isDateInToday(date) {
            Text("Hôm nay")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else {
            Text(formattedDateString(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }
}

public struct CreateOrEditNoteSheet: View {
    public let existingNote: PersonalNote?
    public let courses: [Course]
    public let onSave: (PersonalNote) -> Void
    public let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var checklist: [ChecklistItem]
    @State private var newChecklistItemTitle: String = ""
    @State private var selectedCourseId: String
    @State private var selectedDueDateMode: DueDateMode
    @State private var customDueDate: Date

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

        _title = State(initialValue: existingNote?.title ?? "")
        _content = State(initialValue: existingNote?.content ?? "")
        _checklist = State(initialValue: existingNote?.checklist ?? [])
        _selectedCourseId = State(initialValue: existingNote?.courseId ?? "")

        if let due = existingNote?.dueDate {
            let cal = Calendar.current
            if cal.isDateInToday(due) {
                _selectedDueDateMode = State(initialValue: .today)
                _customDueDate = State(initialValue: due)
            } else if cal.isDateInTomorrow(due) {
                _selectedDueDateMode = State(initialValue: .tomorrow)
                _customDueDate = State(initialValue: due)
            } else {
                _selectedDueDateMode = State(initialValue: .custom)
                _customDueDate = State(initialValue: due)
            }
        } else {
            _selectedDueDateMode = State(initialValue: .none)
            _customDueDate = State(initialValue: Date())
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Tiêu đề") {
                    TextField("Tiêu đề ghi chú / việc cần làm", text: $title)
                }

                Section {
                    ForEach($checklist) { $item in
                        HStack(spacing: 10) {
                            Button {
                                item.isCompleted.toggle()
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
                            }
                            .buttonStyle(.plain)

                            TextField("Nội dung mục...", text: $item.title)
                                .strikethrough(item.isCompleted, color: Color.secondary)
                                .foregroundStyle(item.isCompleted ? Color.secondary : Color.platformTextPrimary)

                            Button(role: .destructive) {
                                checklist.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.blue)

                        TextField("Thêm việc cần làm (nhấn Enter)...", text: $newChecklistItemTitle)
                            .onSubmit {
                                addChecklistItem()
                            }

                        if !newChecklistItemTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Thêm") {
                                addChecklistItem()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    HStack {
                        Text("Danh sách việc cần làm (Checklist)")
                        Spacer()
                        if !checklist.isEmpty {
                            let done = checklist.filter(\.isCompleted).count
                            Text("\(done)/\(checklist.count) việc")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(done == checklist.count ? Color.green : Color.secondary)
                        }
                    }
                }

                Section("Ghi chú chi tiết (tuỳ chọn)") {
                    TextEditor(text: $content)
                        .frame(minHeight: 75)
                }

                Section("Thiết lập môn học & Báo bài") {
                    Picker("Môn học", selection: $selectedCourseId) {
                        Text("Không gắn môn").tag("")
                        ForEach(courses) { course in
                            Text(course.name).tag(course.id)
                        }
                        if !selectedCourseId.isEmpty && !courses.contains(where: { $0.id == selectedCourseId }) {
                            Text(existingNote?.courseName ?? "Môn học").tag(selectedCourseId)
                        }
                    }

                    Picker("Hạn nộp (Báo bài)", selection: $selectedDueDateMode) {
                        ForEach(DueDateMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if selectedDueDateMode == .custom {
                        DatePicker("Chọn ngày & giờ", selection: $customDueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(existingNote == nil ? "Ghi chú mới" : "Chỉnh sửa ghi chú")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ", action: onCancel)
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        save()
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing = existingNote {
                    title = existing.title
                    content = existing.content
                    checklist = existing.checklist
                    selectedCourseId = existing.courseId ?? ""
                    if let due = existing.dueDate {
                        let cal = Calendar.current
                        if cal.isDateInToday(due) {
                            selectedDueDateMode = .today
                            customDueDate = due
                        } else if cal.isDateInTomorrow(due) {
                            selectedDueDateMode = .tomorrow
                            customDueDate = due
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
        .frame(minWidth: 460, minHeight: 460)
        #endif
    }

    private func addChecklistItem() {
        let trimmed = newChecklistItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        checklist.append(ChecklistItem(title: trimmed))
        newChecklistItemTitle = ""
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        // Include any unsaved pending checklist text
        var finalChecklist = checklist
        let pendingItem = newChecklistItemTitle.trimmingCharacters(in: .whitespaces)
        if !pendingItem.isEmpty {
            finalChecklist.append(ChecklistItem(title: pendingItem))
        }

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

        let isDone: Bool
        if let existing = existingNote {
            if !finalChecklist.isEmpty && finalChecklist.allSatisfy({ $0.isCompleted }) {
                isDone = true
            } else {
                isDone = existing.isCompleted
            }
        } else {
            isDone = !finalChecklist.isEmpty && finalChecklist.allSatisfy({ $0.isCompleted })
        }

        let finalNote = PersonalNote(
            id: existingNote?.id ?? UUID().uuidString,
            courseworkId: existingNote?.courseworkId,
            courseId: selectedCourse?.id ?? (selectedCourseId.isEmpty ? nil : selectedCourseId),
            courseName: selectedCourse?.name ?? existingNote?.courseName,
            title: trimmedTitle,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            checklist: finalChecklist,
            dueDate: computedDueDate,
            isCompleted: isDone,
            createdAt: existingNote?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(finalNote)
    }
}
