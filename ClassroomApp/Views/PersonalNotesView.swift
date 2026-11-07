import SwiftUI

public struct PersonalNotesView: View {
    public let notes: [PersonalNote]
    public let courses: [Course]
    public let searchText: String
    public let onToggleCompletion: (String) -> Void
    public let onToggleChecklistItem: ((String, String) -> Void)?
    public let onSaveNote: (PersonalNote) -> Void
    public let onDeleteNote: (String) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedCourseId: String? = nil
    @State private var activeSheet: ActiveNoteSheet? = nil
    @State private var emptyAppeared: Bool = false

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
        case createDraft(title: String, courseId: String?, dueDate: Date?)
        case edit(PersonalNote)

        public var id: String {
            switch self {
            case .create: return "create"
            case .createDraft(let title, let courseId, let due):
                return "draft_\(title)_\(courseId ?? "")_\(due?.timeIntervalSince1970 ?? 0)"
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

        switch selectedStatusFilter {
        case .all:
            break
        case .pending:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        if let courseId = selectedCourseId {
            result = result.filter { $0.courseId == courseId }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            let cleanQuery = query.normalizedForVietnameseSearch()
            let tokens = cleanQuery.searchQueryTokens()
            if !tokens.isEmpty {
                var scored: [(item: PersonalNote, score: Int)] = []
                scored.reserveCapacity(result.count)
                let tokenCount = tokens.count
                for note in result {
                    let index = note.searchIndex
                    var matchesAll = true
                    for t in 0..<tokenCount {
                        if !index.contains(tokens[t]) {
                            matchesAll = false
                            break
                        }
                    }
                    if matchesAll {
                        scored.append((item: note, score: note.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)))
                    }
                }
                guard !scored.isEmpty else { return [] }
                scored.sort { first, second in
                    if first.score != second.score {
                        return first.score > second.score
                    }
                    if first.item.isCompleted != second.item.isCompleted {
                        return !first.item.isCompleted
                    }
                    return first.item.updatedAt > second.item.updatedAt
                }
                var sortedNotes: [PersonalNote] = []
                sortedNotes.reserveCapacity(scored.count)
                for entry in scored {
                    sortedNotes.append(entry.item)
                }
                return sortedNotes
            }
        }

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
            case .createDraft(let initialTitle, let initialCourseId, let initialDueDate):
                CreateOrEditNoteSheet(
                    existingNote: nil,
                    courses: courses,
                    initialTitle: initialTitle,
                    initialCourseId: initialCourseId,
                    initialDueDate: initialDueDate,
                    onSave: { newNote in
                        onSaveNote(newNote)
                        quickTodoTitle = ""
                        quickTodoCourseId = nil
                        quickTodoDue = .none
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateNewPersonalNote"))) { _ in
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
            HStack(spacing: 5) {
                Menu {
                    Button("Tất cả môn") {
                        PlatformHaptics.trigger()
                        selectedCourseId = nil
                    }
                    Divider()
                    ForEach(courses) { course in
                        Button {
                            PlatformHaptics.trigger()
                            selectedCourseId = course.id
                        } label: {
                            if selectedCourseId == course.id {
                                Label(course.name, systemImage: "checkmark")
                            } else {
                                Text(course.name)
                            }
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
                            .foregroundStyle(selectedCourseId != nil ? Color.blue.opacity(0.8) : Color.secondary)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selectedCourseId != nil ? Color.blue : Color.platformTextPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedCourseId != nil ? Color.blue.opacity(0.12) : Color.platformControlBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selectedCourseId != nil ? Color.blue.opacity(0.4) : Color.platformCardBorder, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)

                if selectedCourseId != nil {
                    Button {
                        PlatformHaptics.trigger()
                        selectedCourseId = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Xoá bộ lọc môn")
                    .accessibilityLabel("Xoá bộ lọc môn")
                }
            }
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
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: quickTodoTitle.isEmpty)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: quickTodoDue)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: quickTodoCourseId)
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
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                quickTodoCourseMenu
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            quickTodoExpandButton

            quickTodoSubmitButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.platformControlBackground)
        )
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

                quickTodoExpandButton

                quickTodoSubmitButton
            }

            if !quickTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack(spacing: 6) {
                    quickTodoDueDateMenu
                    quickTodoCourseMenu
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.platformControlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.platformCardBorder, lineWidth: 1)
        )
    }

    private var quickTodoExpandButton: some View {
        Button {
            let due: Date?
            let cal = ClassroomDateFormatters.gregorianCalendar
            switch quickTodoDue {
            case .none:
                due = nil
            case .today:
                due = cal.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
            case .tomorrow:
                if let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) {
                    due = cal.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow)
                } else {
                    due = nil
                }
            case .custom:
                due = nil
            }
            let effectiveCourseId: String? = {
                if let id = quickTodoCourseId {
                    return id.isEmpty ? nil : id
                }
                return selectedCourseId
            }()
            activeSheet = .createDraft(
                title: quickTodoTitle.trimmingCharacters(in: .whitespaces),
                courseId: effectiveCourseId,
                dueDate: due
            )
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Mở rộng biểu mẫu tạo việc đầy đủ")
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
                Button("Không gắn môn") { quickTodoCourseId = "" }
                Divider()
                ForEach(courses) { course in
                    Button(course.name) { quickTodoCourseId = course.id }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "book")
                        .font(.system(size: 10.5))
                    let labelText: String = {
                        if let id = quickTodoCourseId {
                            if id.isEmpty { return "Không gắn môn" }
                            return courses.first(where: { $0.id == id })?.name ?? "Môn"
                        } else if let activeCourseId = selectedCourseId, let course = courses.first(where: { $0.id == activeCourseId }) {
                            return course.name
                        }
                        return "Môn"
                    }()
                    Text(labelText)
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
                .frame(width: 44, height: 44)
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

        PlatformHaptics.trigger()

        let cal = ClassroomDateFormatters.gregorianCalendar
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

        let effectiveCourseId: String? = {
            if let id = quickTodoCourseId {
                return id.isEmpty ? nil : id
            }
            return selectedCourseId
        }()
        let selectedCourse = courses.first(where: { $0.id == effectiveCourseId })

        let newNote = PersonalNote(
            courseId: selectedCourse?.id,
            courseName: selectedCourse?.name,
            title: trimmed,
            content: "",
            checklist: [],
            dueDate: computedDue,
            isCompleted: false
        )
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            onSaveNote(newNote)
            quickTodoTitle = ""
            quickTodoCourseId = nil
            quickTodoDue = .none
        }
    }

    private var notesListView: some View {
        ScrollView {
            #if os(macOS)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 440), spacing: 12, alignment: .top)], spacing: 12) {
                notesForEach
            }
            .padding(16)
            #else
            if horizontalSizeClass == .regular {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 440), spacing: 12, alignment: .top)], spacing: 12) {
                    notesForEach
                }
                .padding(16)
            } else {
                LazyVStack(spacing: 10) {
                    notesForEach
                }
                .padding(16)
            }
            #endif
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
    }

    private var notesForEach: some View {
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

    private var emptyStateInfo: (icon: String, title: String, subtitle: String, buttonTitle: String?, buttonAction: (() -> Void)?) {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmedQuery.isEmpty {
            return (
                icon: "magnifyingglass",
                title: "Không tìm thấy ghi chú phù hợp",
                subtitle: "Không có ghi chú nào khớp với từ khoá \"\(trimmedQuery)\". Thử tìm kiếm với từ khoá khác.",
                buttonTitle: nil,
                buttonAction: nil
            )
        } else if selectedCourseId != nil {
            let courseName = courses.first(where: { $0.id == selectedCourseId })?.name ?? "môn học này"
            return (
                icon: "books.vertical",
                title: "Không có ghi chú cho môn học",
                subtitle: "Chưa có việc cần làm hoặc ghi chú nào được gắn cho \(courseName).",
                buttonTitle: "Xem tất cả môn",
                buttonAction: {
                    PlatformHaptics.trigger()
                    selectedCourseId = nil
                }
            )
        } else if selectedStatusFilter == .pending && notes.contains(where: { $0.courseworkId == nil && $0.isCompleted }) {
            return (
                icon: "party.popper.fill",
                title: "Đã hoàn thành tất cả việc",
                subtitle: "Không còn việc cần làm nào đang chờ xử lý.",
                buttonTitle: "Xem danh sách đã xong",
                buttonAction: {
                    PlatformHaptics.trigger()
                    selectedStatusFilter = .completed
                }
            )
        } else if selectedStatusFilter == .completed {
            return (
                icon: "clock.badge.checkmark",
                title: "Chưa có việc nào hoàn thành",
                subtitle: "Các việc cần làm sau khi đánh dấu xong sẽ được lưu trữ tại đây.",
                buttonTitle: "Xem việc đang làm",
                buttonAction: {
                    PlatformHaptics.trigger()
                    selectedStatusFilter = .pending
                }
            )
        } else {
            return (
                icon: "checklist",
                title: "Chưa có việc cần làm hay ghi chú nào",
                subtitle: "Thêm việc cần làm (to-do), checklist hoặc dặn dò cho việc học để theo dõi trong Báo bài.",
                buttonTitle: "Tạo ghi chú / to-do mới",
                buttonAction: {
                    activeSheet = .create
                }
            )
        }
    }

    private var emptyStateView: some View {
        let info = emptyStateInfo
        return VStack(spacing: 14) {
            Spacer()
            Image(systemName: info.icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .scaleEffect(emptyAppeared ? 1.0 : 0.88)

            Text(info.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.platformTextPrimary)

            Text(info.subtitle)
                .font(.system(size: 13.5))
                .foregroundStyle(Color.platformTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            if let buttonTitle = info.buttonTitle, let buttonAction = info.buttonAction {
                Button {
                    buttonAction()
                } label: {
                    HStack(spacing: 6) {
                        if info.icon == "checklist" {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text(buttonTitle)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 6)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .opacity(emptyAppeared ? 1.0 : 0.0)
        .scaleEffect(reduceMotion ? 1.0 : (emptyAppeared ? 1.0 : 0.95))
        .offset(y: reduceMotion ? 0 : (emptyAppeared ? 0 : 8))
        .onAppear {
            if reduceMotion {
                emptyAppeared = true
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    emptyAppeared = true
                }
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
            Button {
                PlatformHaptics.trigger()
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
                .frame(width: 44, height: 44)
                #else
                .frame(width: 28, height: 28)
                #endif
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundStyle(note.isCompleted ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(note.isCompleted, color: Color.platformTextTertiary)
                        .opacity(note.isCompleted ? 0.72 : 1.0)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: note.isCompleted)

                    if (note.courseName?.isEmpty == false) || note.dueDate != nil {
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: 64, height: 4)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(isAllDone ? Color.green : Color.blue)
                                        .frame(
                                            width: max(0, min(64, 64 * CGFloat(max(0.0, min(1.0, note.checklistProgress))))),
                                            height: 4
                                        )
                                }
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: note.checklistProgress)
                        }
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4.5) {
                        ForEach(note.checklist.prefix(4)) { item in
                            Button {
                                PlatformHaptics.trigger()
                                onToggleChecklistItem(note.id, item.id)
                            } label: {
                                HStack(spacing: 7) {
                                    if #available(macOS 14.0, iOS 17.0, *) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(item.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                                            .frame(width: 16, height: 16)
                                            .symbolEffect(.bounce, value: item.isCompleted)
                                    } else {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(item.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                                            .frame(width: 16, height: 16)
                                    }

                                    Text(item.title)
                                        .font(.system(size: 13))
                                        .foregroundStyle(item.isCompleted ? Color.platformTextTertiary : Color.platformTextSecondary)
                                        .strikethrough(item.isCompleted, color: Color.platformTextTertiary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.24, dampingFraction: 0.75), value: item.isCompleted)
                            #if os(iOS)
                            .frame(minHeight: 34)
                            #endif
                        }
                        if note.checklist.count > 4 {
                            Button {
                                onEdit()
                            } label: {
                                Text("+ \(note.checklist.count - 4) mục khác...")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                    .padding(.leading, 23)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
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
                    #if os(iOS)
                    .frame(width: 44, height: 44)
                    #else
                    .frame(width: 28, height: 28)
                    #endif
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.platformControlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isHovered ? Color.platformCardHoverBorder : Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.04 : 0.015), radius: isHovered ? 5 : 2, x: 0, y: isHovered ? 2 : 1)
        .scaleEffect(isHovered ? 1.008 : 1.0)
        #if os(macOS)
        .onHover { isHovered = $0 }
        #endif
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isHovered)
        .contextMenu {
            Button("Chỉnh sửa") { onEdit() }
            Button("Xoá", role: .destructive) { onDelete() }
        }
    }

    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter
    }()

    private func formattedDateString(from date: Date) -> String {
        Self.cardDateFormatter.string(from: date)
    }

    @ViewBuilder
    private func dueDateBadge(for date: Date) -> some View {
        let calendar = ClassroomDateFormatters.gregorianCalendar
        if calendar.isDateInTomorrow(date) {
            Text("Ngày mai")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.blue)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .layoutPriority(1)
        } else if calendar.isDateInToday(date) {
            Text("Hôm nay")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.orange)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .layoutPriority(1)
        } else {
            Text(formattedDateString(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .layoutPriority(1)
        }
    }
}

public struct CreateOrEditNoteSheet: View {
    public let existingNote: PersonalNote?
    public let courses: [Course]
    public let onSave: (PersonalNote) -> Void
    public let onCancel: () -> Void

    private enum Field: Hashable {
        case title
        case newChecklistItem
    }

    @FocusState private var focusedField: Field?

    @State private var title: String
    @State private var content: String
    @State private var checklist: [ChecklistItem]
    @State private var newChecklistItemTitle: String = ""
    @State private var selectedCourseId: String
    @State private var selectedDueDateMode: DueDateMode
    @State private var customDueDate: Date

    public typealias DueDateMode = PersonalNotesView.DueDateMode

    public init(
        existingNote: PersonalNote?,
        courses: [Course],
        initialTitle: String = "",
        initialCourseId: String? = nil,
        initialDueDate: Date? = nil,
        onSave: @escaping (PersonalNote) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingNote = existingNote
        self.courses = courses
        self.onSave = onSave
        self.onCancel = onCancel

        _title = State(initialValue: existingNote?.title ?? initialTitle)
        _content = State(initialValue: existingNote?.content ?? "")
        _checklist = State(initialValue: existingNote?.checklist ?? [])
        _selectedCourseId = State(initialValue: existingNote?.courseId ?? initialCourseId ?? "")

        let effectiveDue = existingNote?.dueDate ?? initialDueDate
        if let due = effectiveDue {
            let cal = ClassroomDateFormatters.gregorianCalendar
            let comps = cal.dateComponents([.hour, .minute, .second], from: due)
            let isEndOfDay = (comps.hour == 23 && (comps.minute ?? 0) >= 55) || (comps.hour == 0 && (comps.minute ?? 0) == 0 && (comps.second ?? 0) == 0)
            if isEndOfDay && cal.isDateInToday(due) {
                _selectedDueDateMode = State(initialValue: .today)
                _customDueDate = State(initialValue: due)
            } else if isEndOfDay && cal.isDateInTomorrow(due) {
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
                    TextField("", text: $title, prompt: Text("Tiêu đề việc cần làm..."))
                        .textFieldStyle(.plain)
                        .font(.system(size: 14.5, weight: .medium))
                        .focused($focusedField, equals: .title)
                        .onSubmit {
                            focusedField = .newChecklistItem
                        }
                }

                Section {
                    ForEach($checklist) { $item in
                        HStack(spacing: 8) {
                            Button {
                                PlatformHaptics.trigger()
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                                    item.isCompleted.toggle()
                                }
                            } label: {
                                if #available(macOS 14.0, iOS 17.0, *) {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
                                        .symbolEffect(.bounce, value: item.isCompleted)
                                        #if os(iOS)
                                        .frame(width: 44, height: 44)
                                        #else
                                        .frame(width: 28, height: 28)
                                        #endif
                                        .contentShape(Rectangle())
                                } else {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
                                        #if os(iOS)
                                        .frame(width: 44, height: 44)
                                        #else
                                        .frame(width: 28, height: 28)
                                        #endif
                                        .contentShape(Rectangle())
                                }
                            }
                            .buttonStyle(.plain)

                            TextField("", text: $item.title, prompt: Text("Nội dung mục..."))
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .strikethrough(item.isCompleted, color: Color.secondary.opacity(0.7))
                                .foregroundStyle(item.isCompleted ? Color.secondary : Color.platformTextPrimary)
                                .onSubmit {
                                    focusedField = .newChecklistItem
                                }

                            Button(role: .destructive) {
                                PlatformHaptics.trigger()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    checklist.removeAll { $0.id == item.id }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary.opacity(0.7))
                                    #if os(iOS)
                                    .frame(width: 44, height: 44)
                                    #else
                                    .frame(width: 28, height: 28)
                                    #endif
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Xoá mục này")
                        }
                    }
                    .onDelete { indices in
                        PlatformHaptics.trigger()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            checklist.remove(atOffsets: indices)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.blue)

                        TextField("", text: $newChecklistItemTitle, prompt: Text("Thêm việc cần làm (nhấn Enter)..."))
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .focused($focusedField, equals: .newChecklistItem)
                            .onSubmit {
                                addChecklistItem()
                            }

                        if !newChecklistItemTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Thêm") {
                                addChecklistItem()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .transition(.scale.combined(with: .opacity))
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
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Nhập chi tiết, tài liệu tham khảo hoặc dặn dò...")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary.opacity(0.6))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $content)
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .frame(minHeight: 80)
                            #if os(macOS)
                            .scrollContentBackground(.hidden)
                            #elseif os(iOS)
                            .scrollContentBackground(.hidden)
                            #endif
                    }
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
            #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
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
                    .tint(Color.blue)
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
                        let cal = ClassroomDateFormatters.gregorianCalendar
                        let comps = cal.dateComponents([.hour, .minute, .second], from: due)
                        let isEndOfDay = (comps.hour == 23 && (comps.minute ?? 0) >= 55) || (comps.hour == 0 && (comps.minute ?? 0) == 0 && (comps.second ?? 0) == 0)
                        if isEndOfDay && cal.isDateInToday(due) {
                            selectedDueDateMode = .today
                            customDueDate = due
                        } else if isEndOfDay && cal.isDateInTomorrow(due) {
                            selectedDueDateMode = .tomorrow
                            customDueDate = due
                        } else {
                            selectedDueDateMode = .custom
                            customDueDate = due
                        }
                    } else {
                        selectedDueDateMode = .none
                    }
                } else {
                    if title.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            focusedField = .title
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 500, maxWidth: 540, minHeight: 480, idealHeight: 520)
        #elseif os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
    }

    private func addChecklistItem() {
        let trimmed = newChecklistItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        PlatformHaptics.trigger()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            checklist.append(ChecklistItem(title: trimmed))
            newChecklistItemTitle = ""
        }
        focusedField = .newChecklistItem
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        var finalChecklist = checklist
        let pendingItem = newChecklistItemTitle.trimmingCharacters(in: .whitespaces)
        if !pendingItem.isEmpty {
            finalChecklist.append(ChecklistItem(title: pendingItem))
        }
        finalChecklist = finalChecklist.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }

        let cal = ClassroomDateFormatters.gregorianCalendar
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
        if !finalChecklist.isEmpty {
            isDone = finalChecklist.allSatisfy({ $0.isCompleted })
        } else if let existing = existingNote {
            isDone = existing.isCompleted
        } else {
            isDone = false
        }

        let finalNote = PersonalNote(
            id: existingNote?.id ?? UUID().uuidString,
            courseworkId: existingNote?.courseworkId,
            courseId: selectedCourse?.id ?? (selectedCourseId.isEmpty ? nil : selectedCourseId),
            courseName: selectedCourse?.name ?? (selectedCourseId.isEmpty ? nil : existingNote?.courseName),
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
