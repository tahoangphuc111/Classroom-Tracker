import SwiftUI

struct CourseSelectionRow: View, Equatable {
    let course: Course
    let onToggle: () -> Void

    @State private var isHovered: Bool = false

    static func == (lhs: CourseSelectionRow, rhs: CourseSelectionRow) -> Bool {
        lhs.course == rhs.course
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 10) {
                if #available(macOS 14.0, iOS 17.0, *) {
                    Image(systemName: course.isSelectedForWidget ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(course.isSelectedForWidget ? Color.blue : Color.secondary.opacity(0.45))
                        .symbolEffect(.bounce, value: course.isSelectedForWidget)
                } else {
                    Image(systemName: course.isSelectedForWidget ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(course.isSelectedForWidget ? Color.blue : Color.secondary.opacity(0.45))
                }

                SubjectArtBadgeView(courseName: course.name, size: 26)

                VStack(alignment: .leading, spacing: 2.5) {
                    Text(course.name)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.platformTextPrimary)
                        .lineLimit(1)

                    if let section = course.section, !section.isEmpty {
                        Text(section)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.platformTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 4)
            #if os(iOS)
            .padding(.vertical, 8)
            .frame(minHeight: 48)
            #else
            .padding(.vertical, 3.5)
            #endif
            .contentShape(Rectangle())
        }
        .buttonStyle(SpringPressButtonStyle(scale: 0.98))
        .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
