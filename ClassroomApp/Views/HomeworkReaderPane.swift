import SwiftUI

struct HomeworkReaderPane: View {
    let selectedCourseworkIds: Set<String>
    let currentFilteredList: [Coursework]
    let selectedCoursework: Coursework?
    let personalNotes: [PersonalNote]
    let copyFeedbackMessage: String?

    @Binding var courseworkNoteToEditCourseworkId: String?
    @Binding var courseworkNoteEditingText: String

    let onMarkAllDone: (Set<String>) -> Void
    let onDeselectAll: () -> Void
    let onToggleCompletion: (Coursework) -> Void
    let onCopyToClipboard: (String, String) -> Void
    let onSaveCourseworkNote: (Coursework, String) -> Void
    let onTriggerHaptic: () -> Void
    var onToggleChecklistItem: ((String, String) -> Void)? = nil
    var onEditNote: ((String) -> Void)? = nil
    var courses: [Course] = []
    var onSavePersonalNote: ((PersonalNote) -> Void)? = nil

    @State private var editingPersonalNote: PersonalNote? = nil

    @Environment(\.openURL) private var openURL
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        Group {
            if selectedCourseworkIds.count > 1 {
                let selectedItems = currentFilteredList.filter { selectedCourseworkIds.contains($0.id) }
                BatchSelectedSummaryView(
                    selectedItems: selectedItems,
                    onMarkAllDone: {
                        onMarkAllDone(selectedCourseworkIds)
                    },
                    onDeselectAll: {
                        onDeselectAll()
                    }
                )
            } else if let item = selectedCoursework {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ClassroomSubjectBanner(item: item)

                        readerHeaderBar(for: item)

                        ViewThatFits(in: .horizontal) {
                            regularMetaCards(for: item)
                            compactMetaCards(for: item)
                            verticalMetaCards(for: item)
                        }

                        Divider()
                            .overlay(Color.platformDivider)

                        let isPersonalNote = item.id.hasPrefix("note_")
                        let noteId = isPersonalNote ? String(item.id.dropFirst(5)) : ""
                        let personalNoteItem = isPersonalNote ? personalNotes.first(where: { $0.id == noteId }) : nil

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: isPersonalNote ? "doc.plaintext.fill" : "doc.text.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.blue)
                                    Text(isPersonalNote ? "NỘI DUNG VIỆC CẦN LÀM" : "HƯỚNG DẪN BÀI TẬP")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.platformTextSecondary)
                                }

                                Spacer()

                                if let desc = item.description, !desc.isEmpty {
                                    Button {
                                        onCopyToClipboard(desc, item.title)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 11.5))
                                                .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.blue)
                                            Text(copyFeedbackMessage ?? "Sao chép")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.blue)
                                    .help("Sao chép toàn bộ nội dung hướng dẫn")
                                }
                            }

                            if let desc = item.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineSpacing(6.5)
                                    .foregroundStyle(Color.platformTextPrimary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color.platformControlBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.platformCardBorder, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.015), radius: 3, x: 0, y: 1)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(Color.platformTextTertiary)
                                    Text(isPersonalNote ? "Không có nội dung chi tiết." : "Không có mô tả chi tiết.")
                                        .font(.system(size: 14.5))
                                        .foregroundStyle(Color.platformTextSecondary)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.platformControlBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.platformCardBorder, lineWidth: 1)
                                )
                            }
                        }

                        if let pNote = personalNoteItem, pNote.hasChecklist {
                            Divider()
                                .overlay(Color.platformDivider)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checklist")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.blue)
                                        Text("DANH SÁCH VIỆC CON")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.platformTextSecondary)
                                    }

                                    Spacer()

                                    Text("\(pNote.completedChecklistCount)/\(pNote.totalChecklistCount) việc")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(pNote.completedChecklistCount == pNote.totalChecklistCount ? Color.green : Color.secondary)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(pNote.checklist) { checkItem in
                                        Button {
                                            onTriggerHaptic()
                                            onToggleChecklistItem?(pNote.id, checkItem.id)
                                        } label: {
                                            HStack(spacing: 10) {
                                                if #available(macOS 14.0, iOS 17.0, *) {
                                                    Image(systemName: checkItem.isCompleted ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundStyle(checkItem.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                                                        .symbolEffect(.bounce, value: checkItem.isCompleted)
                                                } else {
                                                    Image(systemName: checkItem.isCompleted ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundStyle(checkItem.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                                                }
                                                Text(checkItem.title)
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(checkItem.isCompleted ? Color.platformTextTertiary : Color.platformTextPrimary)
                                                    .strikethrough(checkItem.isCompleted, color: Color.platformTextTertiary)
                                                    .lineLimit(2)
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(SpringPressButtonStyle(scale: 0.98, pressedOpacity: 0.92))
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.platformControlBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.platformCardBorder, lineWidth: 1)
                                )
                            }
                        }

                        if !isPersonalNote {
                            Divider()
                                .overlay(Color.platformDivider)

                            VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.orange)
                                    Text("GHI CHÚ CỦA BẠN")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.platformTextSecondary)
                                }

                                Spacer()

                                if courseworkNoteToEditCourseworkId != item.id {
                                    Button {
                                        let currentNote = personalNotes.first { $0.courseworkId == item.id }
                                        courseworkNoteEditingText = currentNote?.content ?? ""
                                        courseworkNoteToEditCourseworkId = item.id
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: personalNotes.contains { $0.courseworkId == item.id && !$0.content.isEmpty } ? "pencil" : "plus")
                                                .font(.system(size: 11.5))
                                            Text(personalNotes.contains { $0.courseworkId == item.id && !$0.content.isEmpty } ? "Sửa" : "Thêm ghi chú")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundStyle(Color.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if courseworkNoteToEditCourseworkId == item.id {
                                VStack(alignment: .trailing, spacing: 8) {
                                    Group {
                                        if #available(macOS 13.0, iOS 16.0, *) {
                                            TextEditor(text: $courseworkNoteEditingText)
                                                .scrollContentBackground(.hidden)
                                        } else {
                                            TextEditor(text: $courseworkNoteEditingText)
                                        }
                                    }
                                    .font(.system(size: 14.5))
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color.platformControlBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                                    )

                                    HStack(spacing: 8) {
                                        Button("Huỷ") {
                                            courseworkNoteToEditCourseworkId = nil
                                            courseworkNoteEditingText = ""
                                        }
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)

                                        Button("Lưu ghi chú") {
                                            onSaveCourseworkNote(item, courseworkNoteEditingText)
                                            courseworkNoteToEditCourseworkId = nil
                                            courseworkNoteEditingText = ""
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    }
                                }
                            } else if let note = personalNotes.first(where: { $0.courseworkId == item.id }), !note.content.isEmpty {
                                Text(note.content)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.platformTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(Color.orange.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    )
                            } else {
                                Text("Chưa có ghi chú nào cho bài tập này. Nhấn 'Thêm ghi chú' để ghi lời dặn hoặc lưu ý.")
                                    .font(.system(size: 13.5))
                                    .foregroundStyle(Color.platformTextTertiary)
                                    .italic()
                                    .padding(.vertical, 4)
                            }
                        }
                        }

                        Spacer(minLength: 16)

                        HStack {
                            #if os(macOS)
                            Spacer()
                            #endif
                            if isPersonalNote {
                                Button {
                                    onTriggerHaptic()
                                    if let personalNoteItem {
                                        editingPersonalNote = personalNoteItem
                                    } else {
                                        onEditNote?(noteId)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 15.5, weight: .bold))
                                        Text("Chỉnh sửa việc cần làm")
                                            .font(.system(size: 15, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                    }
                                    #if os(macOS)
                                    .frame(maxWidth: 340)
                                    #else
                                    .frame(maxWidth: .infinity)
                                    #endif
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .help("Chỉnh sửa chi tiết việc cần làm này")
                            } else {
                                Button {
                                    onTriggerHaptic()
                                    openURL(item.destinationURL)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.up.right.square.fill")
                                            .font(.system(size: 15.5, weight: .bold))
                                        Text("Mở bài tập trên Classroom")
                                            .font(.system(size: 15, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                        #if os(macOS)
                                        Text("(⌘O)")
                                            .font(.system(size: 12, weight: .medium))
                                            .opacity(0.85)
                                        #endif
                                    }
                                    #if os(macOS)
                                    .frame(maxWidth: 340)
                                    #else
                                    .frame(maxWidth: .infinity)
                                    #endif
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .keyboardShortcut("o", modifiers: [.command])
                                .help("Mở bài tập trực tiếp trên Google Classroom (⌘O)")
                            }
                            #if os(macOS)
                            Spacer()
                            #endif
                        }
                    }
                    #if os(iOS)
                    .padding(horizontalSizeClass == .compact ? 16 : 24)
                    #else
                    .padding(24)
                    #endif
                }
                .background(Color.platformWindowBackground)
                .id(item.id)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 6)),
                    removal: .opacity
                ))
            } else {
                HomeworkReaderEmptyStateView()
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: selectedCoursework?.id)
        .sheet(item: $editingPersonalNote) { note in
            CreateOrEditNoteSheet(
                existingNote: note,
                courses: courses,
                onSave: { updated in
                    onSavePersonalNote?(updated)
                    editingPersonalNote = nil
                },
                onCancel: {
                    editingPersonalNote = nil
                }
            )
        }
    }

    private func regularMetaCards(for item: Coursework) -> some View {
        HStack(spacing: 12) {
            MetaInfoCard(
                icon: "calendar.badge.clock",
                label: "Hạn chót",
                value: item.dayAndTimeString,
                tint: item.urgencyColor
            )

            MetaInfoCard(
                icon: "hourglass",
                label: "Thời gian còn lại",
                value: item.countdownBadgeString,
                tint: item.urgencyColor
            )

            if let maxPoints = item.maxPoints {
                MetaInfoCard(
                    icon: "star.fill",
                    label: "Thang điểm",
                    value: "\(Int(maxPoints)) điểm",
                    tint: .orange
                )
            }
        }
    }

    private func compactMetaCards(for item: Coursework) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MetaInfoCard(
                    icon: "calendar.badge.clock",
                    label: "Hạn chót",
                    value: item.dayAndTimeString,
                    tint: item.urgencyColor
                )

                MetaInfoCard(
                    icon: "hourglass",
                    label: "Thời gian còn lại",
                    value: item.countdownBadgeString,
                    tint: item.urgencyColor
                )
            }

            if let maxPoints = item.maxPoints {
                MetaInfoCard(
                    icon: "star.fill",
                    label: "Thang điểm",
                    value: "\(Int(maxPoints)) điểm",
                    tint: .orange
                )
            }
        }
    }

    private func verticalMetaCards(for item: Coursework) -> some View {
        VStack(spacing: 8) {
            MetaInfoCard(
                icon: "calendar.badge.clock",
                label: "Hạn chót",
                value: item.dayAndTimeString,
                tint: item.urgencyColor
            )

            MetaInfoCard(
                icon: "hourglass",
                label: "Thời gian còn lại",
                value: item.countdownBadgeString,
                tint: item.urgencyColor
            )

            if let maxPoints = item.maxPoints {
                MetaInfoCard(
                    icon: "star.fill",
                    label: "Thang điểm",
                    value: "\(Int(maxPoints)) điểm",
                    tint: .orange
                )
            }
        }
    }

    @ViewBuilder
    private func readerHeaderBar(for item: Coursework) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                readerStatusBadge(for: item)
                Spacer()
                readerActionButtons(for: item)
            }

            VStack(alignment: .leading, spacing: 8) {
                readerStatusBadge(for: item)
                readerActionButtons(for: item)
            }

            VStack(alignment: .leading, spacing: 8) {
                readerStatusBadge(for: item)
                readerToggleCompletionButton(for: item)
                if item.id.hasPrefix("note_") {
                    let noteId = String(item.id.dropFirst(5))
                    Button {
                        onTriggerHaptic()
                        onEditNote?(noteId)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .bold))
                            Text("Chỉnh sửa")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.platformControlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.platformCardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                } else if let desc = item.description, !desc.isEmpty {
                    readerCopyPromptButton(for: item, desc: desc)
                }
            }
        }
    }

    @ViewBuilder
    private func readerStatusBadge(for item: Coursework) -> some View {
        HStack(spacing: 5) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : (item.isOverdue ? "exclamationmark.circle.fill" : "clock.fill"))
                .font(.system(size: 12.5, weight: .bold))
            Text(item.statusTitle.uppercased())
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            (item.isCompleted ? Color(red: 0.12, green: 0.62, blue: 0.35) : (item.isOverdue ? Color(red: 0.88, green: 0.22, blue: 0.20) : Color(red: 0.90, green: 0.48, blue: 0.08)))
                .opacity(0.12)
        )
        .foregroundStyle(
            item.isCompleted ? Color(red: 0.12, green: 0.62, blue: 0.35) : (item.isOverdue ? Color(red: 0.88, green: 0.22, blue: 0.20) : Color(red: 0.90, green: 0.48, blue: 0.08))
        )
        .clipShape(Capsule())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.status)
    }

    @ViewBuilder
    private func readerToggleCompletionButton(for item: Coursework) -> some View {
        Button {
            onToggleCompletion(item)
        } label: {
            HStack(spacing: 5) {
                if #available(macOS 14.0, iOS 17.0, *) {
                    Image(systemName: item.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .symbolEffect(.bounce, value: item.isCompleted)
                } else {
                    Image(systemName: item.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(item.isCompleted ? "Chưa nộp" : "Đã nộp")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                #if os(macOS)
                Text("(Space)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.platformTextTertiary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                #endif
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.platformControlBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.platformCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(SpringPressButtonStyle(scale: 0.96))
        .help("Đánh dấu hoàn thành / Hoàn tác (Phím Space)")
    }

    @ViewBuilder
    private func readerCopyPromptButton(for item: Coursework, desc: String) -> some View {
        Button {
            onCopyToClipboard(desc, item.title)
        } label: {
            HStack(spacing: 5) {
                if #available(macOS 14.0, iOS 17.0, *) {
                    Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.secondary)
                        .symbolEffect(.bounce, value: copyFeedbackMessage != nil)
                } else {
                    Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.secondary)
                }
                Text(copyFeedbackMessage ?? "Sao chép đề")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.platformControlBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.platformCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(SpringPressButtonStyle(scale: 0.96))
        .keyboardShortcut("c", modifiers: [.command, .shift])
        .help("Sao chép đề bài vào bộ nhớ tạm (⌘⇧C)")
    }

    @ViewBuilder
    private func readerActionButtons(for item: Coursework) -> some View {
        HStack(spacing: 8) {
            readerToggleCompletionButton(for: item)
            if item.id.hasPrefix("note_") {
                let noteId = String(item.id.dropFirst(5))
                Button {
                    onTriggerHaptic()
                    onEditNote?(noteId)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                        Text("Chỉnh sửa")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.platformControlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.platformCardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                .help("Chỉnh sửa việc cần làm này")
            } else if let desc = item.description, !desc.isEmpty {
                readerCopyPromptButton(for: item, desc: desc)
            }
        }
    }
}

// MARK: - Supporting Subviews for Reader Pane

struct MetaInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(tint.opacity(0.22), lineWidth: 0.5)
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.platformTextSecondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 15.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHovered ? tint.opacity(0.24) : Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.035 : 0.015), radius: isHovered ? 4 : 2, x: 0, y: 1)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct BatchSelectedSummaryView: View {
    let selectedItems: [Coursework]
    let onMarkAllDone: () -> Void
    let onDeselectAll: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 68, height: 68)

                Image(systemName: "checklist.checked")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }

            VStack(spacing: 5) {
                Text("Đã chọn \(selectedItems.count) bài tập")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                Text("Bạn có thể hoàn thành hàng loạt hoặc bỏ chọn các bài này.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.platformTextSecondary)
            }

            VStack(spacing: 7) {
                ForEach(selectedItems.prefix(5)) { item in
                    HStack(spacing: 8) {
                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 18)

                        Text(item.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.platformTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(item.compactDueString)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Color.platformTextSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.platformControlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.platformCardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.015), radius: 2, x: 0, y: 1)
                }

                if selectedItems.count > 5 {
                    Text("...và \(selectedItems.count - 5) bài tập khác")
                        .font(.caption)
                        .foregroundStyle(Color.platformTextSecondary)
                }
            }
            .frame(maxWidth: 360)

            let allCompleted = !selectedItems.isEmpty && selectedItems.allSatisfy { $0.isCompleted }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Button {
                        onMarkAllDone()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: allCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            Text(allCompleted ? "Đánh dấu tất cả chưa nộp" : "Đánh dấu tất cả đã nộp")
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(allCompleted ? Color.orange : Color(red: 0.12, green: 0.62, blue: 0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button("Bỏ chọn") {
                        onDeselectAll()
                    }
                    .buttonStyle(.bordered)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(spacing: 8) {
                    Button {
                        onMarkAllDone()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: allCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            Text(allCompleted ? "Đánh dấu tất cả chưa nộp" : "Đánh dấu tất cả đã nộp")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(allCompleted ? Color.orange : Color(red: 0.12, green: 0.62, blue: 0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button("Bỏ chọn") {
                        onDeselectAll()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.platformWindowBackground)
    }
}

struct HomeworkReaderEmptyStateView: View {
    @State private var hasAppeared: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            StudyDeskEmberSceneView()
                .scaleEffect(hasAppeared ? 1.0 : 0.90)

            VStack(spacing: 6) {
                Text("Chọn một bài tập từ danh sách bên trái")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                Text("Toàn bộ nội dung, hướng dẫn và hạn nộp chi tiết sẽ hiển thị tại đây")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.platformTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            #if os(macOS)
            shortcutLegendView
                .padding(.top, 8)
                .padding(.horizontal, 16)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .offset(y: hasAppeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                hasAppeared = true
            }
        }
    }

    #if os(macOS)
    @ViewBuilder
    private var shortcutLegendView: some View {
        ViewThatFits(in: .horizontal) {
            // Tier 1: All 5 in a single row (when width >= 490pt)
            HStack(spacing: 8) {
                KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
                KeyboardShortcutPill(shortcut: "⌘O", label: "Mở Classroom")
                KeyboardShortcutPill(shortcut: "⌘F", label: "Tìm kiếm")
                KeyboardShortcutPill(shortcut: "⌘R", label: "Đồng bộ")
            }

            // Tier 2: 2 balanced rows (when width >= 330pt)
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                    KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
                    KeyboardShortcutPill(shortcut: "⌘O", label: "Mở bài")
                }
                HStack(spacing: 8) {
                    KeyboardShortcutPill(shortcut: "⌘F", label: "Tìm kiếm")
                    KeyboardShortcutPill(shortcut: "⌘R", label: "Đồng bộ")
                }
            }

            // Tier 3: 2 compact rows (when width >= 230pt)
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                    KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
                }
                HStack(spacing: 8) {
                    KeyboardShortcutPill(shortcut: "⌘O", label: "Mở bài")
                    KeyboardShortcutPill(shortcut: "⌘F", label: "Tìm")
                }
            }

            // Tier 4: Primary actions in single row (when width >= 190pt)
            HStack(spacing: 8) {
                KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
            }

            // Tier 5: Ultra-compact vertical stack (when width < 190pt)
            VStack(spacing: 4) {
                KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
            }
        }
    }
    #endif
}

struct KeyboardShortcutPill: View {
    let shortcut: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Text(shortcut)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.platformTextPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 2.5)
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.platformCardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.platformTextSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct StudyDeskEmberSceneView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.12), Color.blue.opacity(0.0)],
                        center: .center,
                        startRadius: 15,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 14) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 68, height: 48)
                            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.platformCardBorder, lineWidth: 1)
                            )

                        VStack(spacing: 4) {
                            ForEach(0..<4) { _ in
                                Capsule()
                                    .fill(Color.blue.opacity(0.20))
                                    .frame(width: 50, height: 2)
                            }
                        }

                        Rectangle()
                            .fill(Color.orange.opacity(0.75))
                            .frame(width: 2.5, height: 48)
                    }

                    ChunkyEmberCharacterView(emotion: .normal, size: 54)
                        .offset(y: 4)

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.platformControlBackground)
                            .frame(width: 20, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.platformCardBorder, lineWidth: 1)
                            )

                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2.5, height: 34)
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: 3.5, height: 38)
                        }
                        .offset(y: -4)
                    }
                }

                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color.platformCardBorder)
                    .frame(width: 180, height: 3.5)
                    .padding(.top, 4)
            }
        }
        .frame(height: 110)
    }
}
