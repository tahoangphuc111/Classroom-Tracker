import SwiftUI

struct CompactCourseFilterSheet: View {
    let courses: [Course]
    @Binding var isPresented: Bool
    let onToggleCourse: (String) -> Void
    let onToggleAllCourses: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if courses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.secondary)
                        Text("Chưa có danh sách môn học")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.platformTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(courses) { course in
                            CourseSelectionRow(
                                course: course,
                                onToggle: {
                                    onToggleCourse(course.id)
                                }
                            )
                            .equatable()
                        }
                    } header: {
                        HStack {
                            Text("Lớp hiển thị (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                            Spacer()
                            let allSelected = courses.allSatisfy(\.isSelectedForWidget)
                            AdaptiveGlassContainer(spacing: 6) {
                                Button(allSelected ? "Bỏ chọn hết" : "Tất cả") {
                                    onToggleAllCourses()
                                }
                                .buttonStyle(.plain)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(allSelected ? Color.secondary : Color.blue)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .appleLiquidGlassSurface(
                                    style: .interactiveTint(allSelected ? Color.secondary.opacity(0.12) : Color.blue.opacity(0.12)),
                                    in: Capsule()
                                ) {
                                    Capsule().fill(allSelected ? Color.platformControlBackground : Color.blue.opacity(0.10))
                                }
                                .overlay(
                                    Capsule().stroke(allSelected ? Color.platformCardBorder : Color.blue.opacity(0.24), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle("Lọc môn học")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    AdaptiveGlassContainer(spacing: 4) {
                        Button("Xong") {
                            isPresented = false
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .appleLiquidGlassSurface(
                            style: .interactiveTint(Color.blue.opacity(0.12)),
                            in: Capsule()
                        ) {
                            Capsule().fill(Color.blue.opacity(0.10))
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
