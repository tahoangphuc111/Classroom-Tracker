import SwiftUI

struct RowSelectedShadowModifier: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected {
            #if os(macOS)
            content.shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            #else
            content.shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            #endif
        } else {
            content
        }
    }
}

struct SectionHeaderPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Spacer()

            Text("\(count) bài")
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.14), lineWidth: 1)
        )
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

struct SubjectGroupHeaderRow: View {
    let courseName: String
    let count: Int

    var body: some View {
        let themeColor = SubjectArtHelper.themeColor(for: courseName)

        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(themeColor)
                .frame(width: 4, height: 15)

            Text(courseName.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextPrimary)

            Text("\(count) bài")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(themeColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(themeColor.opacity(0.12), in: Capsule())

            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

struct CompletedSectionHeaderRow: View {
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(Color.green)

            Text("ĐÃ HOÀN THÀNH (\(count))")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextSecondary)

            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }
}

struct AssignmentListRow: View, Equatable {
    let item: Coursework
    let isSelected: Bool
    var isWide: Bool = true
    var hasNote: Bool = false
    let onSelect: (Bool) -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false
    @Environment(\.openURL) private var openURL

    static func == (lhs: AssignmentListRow, rhs: AssignmentListRow) -> Bool {
        lhs.item == rhs.item && lhs.isSelected == rhs.isSelected && lhs.hasNote == rhs.hasNote && lhs.isWide == rhs.isWide
    }

    var isTurnedIn: Bool {
        item.isCompleted
    }

    var body: some View {
        let themeColor = SubjectArtHelper.themeColor(for: item.courseName, title: item.title)

        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 9) {
                Capsule()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 3.5, height: 34)
                    .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isSelected)
                    .contentShape(Rectangle().inset(by: -8))
                    .onTapGesture {
                        #if os(macOS)
                        let isCmd = NSEvent.modifierFlags.contains(.command)
                        #else
                        let isCmd = false
                        #endif
                        onSelect(isCmd)
                    }

                Button {
                    onToggleCompletion()
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 34)
                            .equatable()

                        if isTurnedIn {
                            if #available(macOS 14.0, iOS 17.0, *) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15.5, weight: .bold))
                                    .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                                    .background(Circle().fill(Color.white).padding(1))
                                    .offset(x: 3, y: 3)
                                    .scaleEffect(checkmarkBounce ? 1.32 : 1.0)
                                    .symbolEffect(.bounce, value: isTurnedIn)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15.5, weight: .bold))
                                    .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                                    .background(Circle().fill(Color.white).padding(1))
                                    .offset(x: 3, y: 3)
                                    .scaleEffect(checkmarkBounce ? 1.32 : 1.0)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                            }
                        } else {
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.3)
                                .background(Circle().fill(Color.platformControlBackground.opacity(0.85)))
                                .frame(width: 14, height: 14)
                                .offset(x: 2, y: 2)
                                .scaleEffect(checkmarkBounce ? 0.9 : 1.0)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                    }
                    .scaleEffect(checkmarkBounce ? 1.15 : 1.0)
                }
                #if os(macOS)
                .frame(width: 36, height: 36)
                #else
                .frame(width: 44, height: 44)
                #endif
                .contentShape(Rectangle())
                .buttonStyle(SpringPressButtonStyle(scale: 0.92, pressedOpacity: 0.88))
                .help(isTurnedIn ? "Đã nộp bài (Space hoặc bấm để hoàn tác)" : "Chưa nộp bài (Space hoặc bấm để đánh dấu hoàn thành)")
            }
            .padding(.leading, 11)
            .padding(.trailing, 9)

            HStack(alignment: .center, spacing: 9) {
                VStack(alignment: .leading, spacing: 4) {
                    #if os(macOS)
                    Text(item.title)
                        .font(.system(size: 15.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                        .opacity(isTurnedIn ? 0.72 : 1.0)
                        .lineLimit(2)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 7, height: 7)
                        Text(item.courseName)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(themeColor)
                            .lineLimit(1)
                        if hasNote {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .opacity(isTurnedIn ? 0.75 : 1.0)
                    #else
                    Text(item.title)
                        .font(.system(size: 17.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                        .opacity(isTurnedIn ? 0.72 : 1.0)
                        .lineLimit(2)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 7, height: 7)
                        Text(item.courseName)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(themeColor)
                            .lineLimit(1)
                        if hasNote {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .opacity(isTurnedIn ? 0.75 : 1.0)
                    #endif
                }

                Spacer(minLength: 8)

                DueBadgeView(item: item, compact: true)
                    .equatable()
                    .layoutPriority(1)
            }
            .padding(.trailing, 11)
            #if os(iOS)
            .padding(.vertical, 11)
            .frame(minHeight: 66)
            #else
            .padding(.vertical, 8)
            #endif
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                #if os(macOS)
                let isCmd = NSEvent.modifierFlags.contains(.command)
                #else
                let isCmd = false
                #endif
                onSelect(isCmd)
            }
        }
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.platformCardSelectedBackground : Color.platformControlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected ? Color.platformCardSelectedBorder : (isHovered ? Color.platformCardHoverBorder : Color.platformCardBorder),
                    lineWidth: isSelected ? 1.2 : 1
                )
        )
        .modifier(RowSelectedShadowModifier(isSelected: isSelected))
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
        .onChange(of: isTurnedIn) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                checkmarkBounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                    checkmarkBounce = false
                }
            }
        }
        .contextMenu {
            Button {
                onToggleCompletion()
            } label: {
                Label(
                    isTurnedIn ? "Đánh dấu chưa nộp" : "Đánh dấu đã nộp",
                    systemImage: isTurnedIn ? "arrow.uturn.backward" : "checkmark.circle"
                )
            }

            Button {
                PlatformClipboard.copy(item.title)
            } label: {
                Label("Sao chép tiêu đề", systemImage: "doc.on.doc")
            }

            if let link = item.alternateLink, let url = URL(string: link) {
                Button {
                    PlatformClipboard.copy(link)
                } label: {
                    Label("Sao chép liên kết", systemImage: "link")
                }

                Button {
                    openURL(url)
                } label: {
                    Label("Mở trên Google Classroom", systemImage: "arrow.up.right")
                }
            }
        }
    }
}
