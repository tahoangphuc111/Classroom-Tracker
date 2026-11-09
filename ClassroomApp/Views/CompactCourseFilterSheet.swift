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
                            .font(.system(size: 30))
                            .foregroundStyle(Color.secondary)
                        Text("Chưa có danh sách môn học")
                            .font(.system(size: 15.5, weight: .medium))
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
                                    PlatformHaptics.trigger()
                                    withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                                        onToggleCourse(course.id)
                                    }
                                }
                            )
                            .equatable()
                            #if os(iOS)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.platformControlBackground.opacity(0.72))
                            )
                            #endif
                        }
                    } header: {
                        HStack {
                            Text("Lớp hiển thị (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                            Spacer()
                            let allSelected = courses.allSatisfy(\.isSelectedForWidget)
                            Button(allSelected ? "Bỏ chọn hết" : "Tất cả") {
                                PlatformHaptics.trigger()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    onToggleAllCourses()
                                }
                            }
                            .buttonStyle(SpringPressButtonStyle(scale: 0.94, pressedOpacity: 0.88))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(allSelected ? Color.secondary : Color.blue)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(allSelected ? Color.platformControlBackground : Color.blue.opacity(0.10))
                            )
                            .overlay(
                                Capsule().stroke(allSelected ? Color.platformCardBorder : Color.blue.opacity(0.24), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #else
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            #endif
            .navigationTitle("Lọc môn học")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        PlatformHaptics.trigger()
                        isPresented = false
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.green))
                    }
                    .accessibilityLabel("Xong")
                    .buttonStyle(SpringPressButtonStyle(scale: 0.94, pressedOpacity: 0.88))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }
}
