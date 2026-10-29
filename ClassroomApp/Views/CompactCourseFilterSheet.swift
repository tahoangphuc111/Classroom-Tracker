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
                            Button(allSelected ? "Bỏ chọn hết" : "Tất cả") {
                                onToggleAllCourses()
                            }
                            .buttonStyle(.plain)
                            .font(.caption2)
                            .foregroundStyle(.blue)
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
                    Button("Xong") {
                        isPresented = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
