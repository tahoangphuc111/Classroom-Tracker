import SwiftUI
import WidgetKit
#if os(macOS)
import AppKit
#endif

public struct ContentView: View {
    @StateObject private var authService = GoogleOAuthService.shared
    @StateObject private var apiService = ClassroomAPIService.shared
    @StateObject private var updateService = AppUpdateService.shared

    @State private var courses: [Course] = []
    @State private var allCoursework: [Coursework] = []
    @State private var selectedFilter: AppFilterCategory = .tomorrow
    @State private var selectedCoursework: Coursework? = nil
    @State private var selectedPreviewFamily: WidgetPreviewFamily = .medium
    @State private var useSampleDataForPreview: Bool = false
    @State private var showSettingsModal: Bool = false
    @State private var clientIdInput: String = ""
    @State private var clientSecretInput: String = ""
    @State private var isSigningIn: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchText: String = ""
    @State private var copyFeedbackMessage: String? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var activeToast: ToastMessage? = nil
    @State private var toastDismissTask: Task<Void, Never>? = nil
    @State private var syncRotationAngle: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    enum AppFilterCategory: String, CaseIterable, Identifiable {
        case tomorrow = "Báo bài Ngày mai"
        case todayAndTomorrow = "Hôm nay & Ngày mai"
        case allUpcoming = "Tất cả sắp tới"
        case past = "Đã qua hạn"
        case completed = "Đã hoàn thành"
        case widgetPreview = "Xem trước Widget"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .tomorrow: return "calendar.badge.clock"
            case .todayAndTomorrow: return "clock"
            case .allUpcoming: return "tray"
            case .past: return "clock.badge.exclamationmark"
            case .completed: return "checkmark.seal"
            case .widgetPreview: return "macwindow"
            }
        }
    }

    enum WidgetPreviewFamily: String, CaseIterable, Identifiable {
        case small = "Nhỏ"
        case medium = "Vừa"
        case large = "Lớn"
        var id: String { rawValue }
    }

    public init() {}

    private var todayItems: [Coursework] {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        return allCoursework
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { $0.isDueToday }
            .sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
    }

    private var tomorrowItems: [Coursework] {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        return allCoursework
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { $0.isDueTomorrow }
            .sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
    }

    private var laterUpcomingItems: [Coursework] {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        return allCoursework
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { $0.isDueLater }
            .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    private var pastItems: [Coursework] {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        return allCoursework
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { $0.isPast || $0.isOverdue }
            .sorted { ($0.dueDate ?? Date.distantPast) > ($1.dueDate ?? Date.distantPast) }
    }

    private var noDueDateItems: [Coursework] {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        return allCoursework
            .filter { activeCourseIds.contains($0.courseId) }
            .filter { $0.status != .turnedIn && $0.status != .returned }
            .filter { $0.hasNoDueDate }
            .sorted { $0.title < $1.title }
    }

    private var completedItems: [Coursework] {
        allCoursework.filter { $0.status == .turnedIn || $0.status == .returned }
    }

    private var widgetItems: [Coursework] {
        todayItems + tomorrowItems
    }

    private var resolvedPreviewColorScheme: ColorScheme {
        .light
    }

    private var itemsForPreview: [Coursework] {
        if useSampleDataForPreview || widgetItems.isEmpty {
            return ClassroomStorage.mockCoursework
                .filter { $0.isDueTodayOrTomorrow }
                .sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        }
        return widgetItems
    }

    private var currentFilteredList: [Coursework] {
        let baseList: [Coursework]
        switch selectedFilter {
        case .tomorrow:
            baseList = tomorrowItems
        case .todayAndTomorrow:
            baseList = todayItems + tomorrowItems
        case .allUpcoming:
            baseList = todayItems + tomorrowItems + laterUpcomingItems + noDueDateItems
        case .past:
            baseList = pastItems
        case .completed:
            baseList = completedItems
        case .widgetPreview:
            baseList = []
        }

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return baseList
        } else {
            let cleanQuery = searchText.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            return baseList.filter { item in
                let titleMatch = item.title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).contains(cleanQuery)
                let courseMatch = item.courseName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).contains(cleanQuery)
                let descMatch = item.description?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).contains(cleanQuery) ?? false
                return titleMatch || courseMatch || descMatch
            }
        }
    }

    public var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailMasterView
        }
        .onAppear {
            clientIdInput = authService.configuredClientId
            clientSecretInput = authService.configuredClientSecret
            refreshData()
            autoSelectFirstItem()
            if authService.isAuthenticated {
                Task {
                    await apiService.syncAll()
                    refreshData()
                    autoSelectFirstItem()
                }
            }
            Task {
                await updateService.checkForUpdates()
            }
        }
        .onChange(of: selectedFilter) {
            autoSelectFirstItem()
        }
        .sheet(isPresented: $showSettingsModal) {
            settingsSheetView
        }
    }

    private var sidebarView: some View {
        List(selection: $selectedFilter) {
            Section("Danh mục báo bài") {
                Label {
                    HStack {
                        Text(AppFilterCategory.tomorrow.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        let count = tomorrowItems.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .contentTransition(.numericText())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } icon: {
                    Image(systemName: AppFilterCategory.tomorrow.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .tag(AppFilterCategory.tomorrow)

                Label {
                    HStack {
                        Text(AppFilterCategory.todayAndTomorrow.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        let count = widgetItems.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .contentTransition(.numericText())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } icon: {
                    Image(systemName: AppFilterCategory.todayAndTomorrow.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
                .tag(AppFilterCategory.todayAndTomorrow)

                Label {
                    HStack {
                        Text(AppFilterCategory.allUpcoming.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        let total = todayItems.count + tomorrowItems.count + laterUpcomingItems.count + noDueDateItems.count
                        if total > 0 {
                            Text("\(total)")
                                .font(.system(size: 10, weight: .semibold))
                                .contentTransition(.numericText())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .foregroundStyle(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } icon: {
                    Image(systemName: AppFilterCategory.allUpcoming.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                }
                .tag(AppFilterCategory.allUpcoming)

                Label {
                    HStack {
                        Text(AppFilterCategory.past.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        let count = pastItems.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .contentTransition(.numericText())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } icon: {
                    Image(systemName: AppFilterCategory.past.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                .tag(AppFilterCategory.past)

                Label {
                    HStack {
                        Text(AppFilterCategory.completed.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        let count = completedItems.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .contentTransition(.numericText())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } icon: {
                    Image(systemName: AppFilterCategory.completed.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                .tag(AppFilterCategory.completed)
            }

            Section("Cấu hình Widget") {
                Label {
                    Text(AppFilterCategory.widgetPreview.rawValue)
                        .font(.system(size: 13, weight: .medium))
                } icon: {
                    Image(systemName: AppFilterCategory.widgetPreview.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.purple)
                }
                .tag(AppFilterCategory.widgetPreview)
            }

            Section {
                ForEach($courses) { $course in
                    HStack(alignment: .center, spacing: 9) {
                        Toggle("", isOn: $course.isSelectedForWidget)
                            .labelsHidden()
                            .toggleStyle(.checkbox)
                            .controlSize(.small)

                        SubjectArtBadgeView(courseName: course.name, size: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)

                            if let section = course.section, !section.isEmpty {
                                Text(section)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        course.isSelectedForWidget.toggle()
                        ClassroomStorage.shared.saveCourses(courses)
                        refreshData()
                    }
                    .onChange(of: course.isSelectedForWidget) {
                        ClassroomStorage.shared.saveCourses(courses)
                        refreshData()
                    }
                }
            } header: {
                HStack {
                    Text("Lớp hiển thị (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                    Spacer()
                    Button("Tất cả") {
                        for i in courses.indices { courses[i].isSelectedForWidget = true }
                        ClassroomStorage.shared.saveCourses(courses)
                        refreshData()
                    }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Classroom")
        .frame(minWidth: 230)
    }

    @ViewBuilder
    private var detailMasterView: some View {
        VStack(spacing: 0) {
            headerBarView

            if updateService.updateAvailable {
                updateBannerView
            }

            Divider()

            if selectedFilter == .widgetPreview {
                ScrollView {
                    widgetPreviewSection
                        .padding(24)
                }
            } else {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        assignmentListPane
                            .frame(width: max(320, geometry.size.width * 0.42))

                        Divider()

                        homeworkReaderPane
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = activeToast {
                FloatingToastHUD(toast: toast, onDismiss: { dismissToast() })
                    .padding(.bottom, 22)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.92))
                    ))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: activeToast)
        .background {
            Group {
                Button("") { selectNextItem() }
                    .keyboardShortcut(.downArrow, modifiers: [])
                Button("") { selectPreviousItem() }
                    .keyboardShortcut(.upArrow, modifiers: [])
                Button("") { isSearchFocused = true }
                    .keyboardShortcut("f", modifiers: [.command])
            }
            .opacity(0)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        triggerHapticFeedback()
                        await apiService.syncAll()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            refreshData()
                            autoSelectFirstItem()
                        }
                        showToast(
                            title: "Đồng bộ hoàn tất!",
                            subtitle: "Đã cập nhật dữ liệu mới nhất từ Classroom",
                            icon: "arrow.triangle.2.circlepath",
                            tint: .blue
                        )
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .rotationEffect(.degrees(syncRotationAngle))
                        Text(apiService.isSyncing ? "Đang đồng bộ..." : "Đồng bộ")
                    }
                }
                .onChange(of: apiService.isSyncing) {
                    if apiService.isSyncing {
                        withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                            syncRotationAngle = 360
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            syncRotationAngle = 0
                        }
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(apiService.isSyncing || !authService.isAuthenticated)
                .help("Đồng bộ bài tập từ Google Classroom (⌘R)")
            }

            ToolbarItem {
                Button {
                    clientIdInput = authService.configuredClientId
                    clientSecretInput = authService.configuredClientSecret
                    showSettingsModal = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Cài đặt tài khoản & dữ liệu mẫu")
            }
        }
    }

    private var headerBarView: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedFilter.rawValue)
                    .font(.system(size: 18, weight: .bold))
                Text(formattedCurrentDate())
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selectedFilter == .widgetPreview {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.purple)
                    Text("Cấu hình & Xem trước Widget")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            if authService.isAuthenticated {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.square")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(authService.currentUserEmail ?? "Đã kết nối")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var updateBannerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
                .font(.system(size: 14, weight: .semibold))

            Text("Đã có bản cập nhật Classroom Tracker v\(updateService.latestVersion)!")
                .font(.system(size: 13, weight: .medium))

            Spacer()

            if updateService.isDownloading {
                ProgressView().controlSize(.small)
                Text("Đang tải...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button("Cập nhật ngay") {
                    Task {
                        await updateService.downloadAndInstall()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.10))
    }

    private var assignmentListPane: some View {
        let list = currentFilteredList
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSearchFocused ? .blue : .secondary)

                TextField("Tìm kiếm bài tập... (⌘F)", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isSearchFocused)
                    .onSubmit {
                        isSearchFocused = false
                    }

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSearchFocused ? Color.blue.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .animation(.easeInOut(duration: 0.15), value: isSearchFocused)

            if !searchText.isEmpty {
                HStack {
                    Text("Tìm thấy \(list.count) bài tập")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            Divider()

            if list.isEmpty {
                AssignmentListEmptyView(
                    filter: selectedFilter,
                    isSearching: !searchText.trimmingCharacters(in: .whitespaces).isEmpty,
                    searchText: searchText,
                    onClearSearch: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if selectedFilter == .todayAndTomorrow || selectedFilter == .allUpcoming {
                            let tomorrows = list.filter { $0.isDueTomorrow }
                            let todays = list.filter { $0.isDueToday }
                            let laters = list.filter { $0.isDueLater }
                            let noDueDates = list.filter { $0.hasNoDueDate }
                            let pasts = list.filter { $0.isPast }

                            if !todays.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(red: 1.0, green: 0.46, blue: 0.12))
                                    Text("HÔM NAY")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(red: 1.0, green: 0.46, blue: 0.12))
                                    Spacer()
                                    Text("\(todays.count) bài")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(red: 1.0, green: 0.46, blue: 0.12))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color(red: 1.0, green: 0.46, blue: 0.12).opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 2)

                                ForEach(todays) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCoursework?.id == item.id,
                                        onSelect: { selectItem(item) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                }
                            }

                            if !tomorrows.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 1.0))
                                    Text("NGÀY MAI")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 1.0))
                                    Spacer()
                                    Text("\(tomorrows.count) bài")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 1.0))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color(red: 0.12, green: 0.54, blue: 1.0).opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, todays.isEmpty ? 2 : 10)

                                ForEach(tomorrows) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCoursework?.id == item.id,
                                        onSelect: { selectItem(item) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                }
                            }

                            if !laters.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text("SẮP TỚI")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(laters.count) bài")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 10)

                                ForEach(laters) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCoursework?.id == item.id,
                                        onSelect: { selectItem(item) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                }
                            }

                            if !noDueDates.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text("KHÔNG CÓ HẠN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(noDueDates.count) bài")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 10)

                                ForEach(noDueDates) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCoursework?.id == item.id,
                                        onSelect: { selectItem(item) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                }
                            }

                            if !pasts.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.red)
                                    Text("QUÁ HẠN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.red)
                                    Spacer()
                                    Text("\(pasts.count) bài")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color.red.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 10)

                                ForEach(pasts) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCoursework?.id == item.id,
                                        onSelect: { selectItem(item) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                }
                            }
                        } else {
                            ForEach(list) { item in
                                AssignmentListRow(
                                    item: item,
                                    isSelected: selectedCoursework?.id == item.id,
                                    onSelect: { selectItem(item) },
                                    onToggleCompletion: { toggleCompletion(for: item) }
                                )
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var homeworkReaderPane: some View {
        Group {
            if let item = selectedCoursework {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ClassroomSubjectBanner(item: item)

                        HStack(alignment: .center, spacing: 10) {
                            Text(item.statusTitle)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(item.status == .turnedIn ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                .foregroundStyle(item.status == .turnedIn ? Color.green : Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.status)

                            Spacer()

                            Button {
                                toggleCompletion(for: item)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: item.status == .turnedIn ? "arrow.uturn.backward" : "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(item.status == .turnedIn ? "Chưa nộp" : "Đã nộp")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("(Space)")
                                        .font(.system(size: 9.5))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .keyboardShortcut(.space, modifiers: [])
                            .help("Đánh dấu hoàn thành / Hoàn tác (Phím Space)")

                            if let desc = item.description, !desc.isEmpty {
                                Button {
                                    copyToClipboard(desc, title: item.title)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 10))
                                            .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.secondary)
                                        Text(copyFeedbackMessage ?? "Sao chép đề")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .keyboardShortcut("c", modifiers: [.command, .shift])
                                .help("Sao chép đề bài vào bộ nhớ tạm (⌘⇧C)")
                            }
                        }

                        HStack(spacing: 12) {
                            MetaInfoCard(
                                icon: "clock",
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
                                    icon: "star",
                                    label: "Thang điểm",
                                    value: "\(Int(maxPoints)) điểm",
                                    tint: .secondary
                                )
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Text("NỘI DUNG & HƯỚNG DẪN BÀI TẬP")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let desc = item.description, !desc.isEmpty {
                                    Button {
                                        copyToClipboard(desc, title: item.title)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 10))
                                                .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.blue)
                                            Text(copyFeedbackMessage ?? "Sao chép nội dung")
                                                .font(.system(size: 10.5, weight: .medium))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.blue)
                                    .help("Sao chép toàn bộ nội dung hướng dẫn")
                                }
                            }

                            if let desc = item.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 13.5, weight: .regular))
                                    .lineSpacing(5)
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            } else {
                                Text("Không có mô tả chi tiết cho bài tập này.")
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(.secondary)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.primary.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        Spacer(minLength: 20)

                        if let link = item.alternateLink, let url = URL(string: link) {
                            Button {
                                triggerHapticFeedback()
                                #if os(macOS)
                                NSWorkspace.shared.open(url)
                                #endif
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Mở bài tập trên Google Classroom để nộp bài")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("(⌘O)")
                                        .font(.system(size: 11, weight: .medium))
                                        .opacity(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut("o", modifiers: [.command])
                            .help("Mở bài tập trực tiếp trên Google Classroom (⌘O)")
                        }
                    }
                    .padding(24)
                }
                .background(Color(NSColor.windowBackgroundColor))
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
    }

    private var widgetPreviewSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Xem trước Widget trên màn hình")
                        .font(.headline)
                    Text("Widget sẽ hiển thị tương tự khi bạn thêm vào màn hình Desktop trên macOS.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Text("Kích thước:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()

                        Picker("", selection: $selectedPreviewFamily) {
                            ForEach(WidgetPreviewFamily.allCases) { family in
                                Text(family.rawValue).tag(family)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }

                    Spacer(minLength: 12)

                    Toggle("Dữ liệu mẫu", isOn: $useSampleDataForPreview)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .fixedSize()
                }

                if widgetItems.isEmpty && !useSampleDataForPreview {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Chưa có bài tập đến hạn hôm nay & mai (đang tự động dùng dữ liệu mẫu)")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.92, blue: 0.98),
                                    Color(red: 0.92, green: 0.88, blue: 0.96),
                                    Color(red: 0.86, green: 0.90, blue: 0.97)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .frame(height: selectedPreviewFamily == .large ? 390 : 220)

                    Group {
                        switch selectedPreviewFamily {
                        case .small:
                            SmallWidgetView(courseworkList: itemsForPreview)
                                .frame(width: 155, height: 155)
                        case .medium:
                            MediumWidgetView(courseworkList: itemsForPreview)
                                .frame(width: 325, height: 155)
                        case .large:
                            LargeWidgetView(courseworkList: itemsForPreview)
                                .frame(width: 325, height: 325)
                        }
                    }
                    .background {
                        WidgetCardBackground()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
                    .environment(\.colorScheme, .light)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPreviewFamily)
            }
            .padding(18)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            desktopGuideCard
        }
    }

    private var desktopGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "macbook.and.iphone")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Hướng dẫn đưa Widget ra màn hình Desktop (macOS Sonoma / Sequoia)")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                GuideStepRow(step: "1", text: "Click chuột phải vào bất kỳ vị trí trống nào trên màn hình Desktop của bạn.")
                GuideStepRow(step: "2", text: "Chọn 'Chỉnh sửa tiện ích...' (Edit Widgets...).")
                GuideStepRow(step: "3", text: "Tìm kiếm 'Classroom Hôm nay & Ngày mai' trong danh sách tiện ích bên dưới.")
                GuideStepRow(step: "4", text: "Kéo thả widget với kích thước mong muốn (Nhỏ, Vừa, Lớn) ra màn hình chính!")
            }
        }
        .padding(18)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }

    private var settingsSheetView: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Google Client ID", text: $clientIdInput)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Google Client Secret (Tùy chọn)", text: $clientSecretInput)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Cấu hình Google Cloud OAuth")
                } footer: {
                    Text("Lấy Client ID từ Google Cloud Console (loại ứng dụng iOS/macOS hoặc Desktop). Redirect URI đặt là: classroomwidget://oauth-callback")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Dữ liệu thử nghiệm") {
                    Button("Nạp lại dữ liệu mẫu (Mock Data hôm nay & mai)") {
                        ClassroomStorage.shared.saveCourses(ClassroomStorage.mockCourses)
                        ClassroomStorage.shared.saveCoursework(ClassroomStorage.mockCoursework)
                        refreshData()
                        autoSelectFirstItem()
                        showSettingsModal = false
                    }
                }

                Section("Cập nhật ứng dụng") {
                    HStack {
                        Text("Phiên bản hiện tại:")
                        Spacer()
                        Text("v\(updateService.currentVersion)")
                            .foregroundStyle(.secondary)
                    }

                    TextField("GitHub Token (dành cho repo riêng tư)", text: Binding(
                        get: { updateService.githubToken },
                        set: { updateService.githubToken = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    if !updateService.statusMessage.isEmpty {
                        Text(updateService.statusMessage)
                            .font(.caption2)
                            .foregroundStyle(updateService.updateAvailable ? .blue : .secondary)
                    }

                    if updateService.updateAvailable {
                        Button {
                            Task {
                                await updateService.downloadAndInstall()
                            }
                        } label: {
                            HStack {
                                if updateService.isDownloading {
                                    ProgressView().controlSize(.small)
                                    Text("Đang tải bản cập nhật...")
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Cập nhật lên v\(updateService.latestVersion) ngay")
                                }
                            }
                        }
                        .disabled(updateService.isDownloading)
                    } else {
                        Button {
                            Task {
                                await updateService.checkForUpdates(isUserInitiated: true)
                            }
                        } label: {
                            HStack {
                                if updateService.isChecking {
                                    ProgressView().controlSize(.small)
                                    Text("Đang kiểm tra...")
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Kiểm tra bản cập nhật mới")
                                }
                            }
                        }
                        .disabled(updateService.isChecking)
                    }
                }

                if authService.isAuthenticated {
                    Section("Tài khoản hiện tại") {
                        HStack {
                            Text("Email:")
                            Spacer()
                            Text(authService.currentUserEmail ?? "Không rõ")
                                .foregroundStyle(.secondary)
                        }

                        Button("Đăng xuất", role: .destructive) {
                            authService.signOut()
                            refreshData()
                            autoSelectFirstItem()
                            showSettingsModal = false
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Cài đặt & Tài khoản")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showSettingsModal = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu & Đăng nhập") {
                        authService.configuredClientId = clientIdInput
                        authService.configuredClientSecret = clientSecretInput
                        showSettingsModal = false
                        startGoogleLogin()
                    }
                    .disabled(clientIdInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .frame(minWidth: 460, minHeight: 340)
        }
    }

    private func triggerHapticFeedback() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        #endif
    }

    private func showToast(
        title: String,
        subtitle: String? = nil,
        icon: String = "info.circle.fill",
        tint: Color = .blue,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        toastDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            activeToast = ToastMessage(
                title: title,
                subtitle: subtitle,
                icon: icon,
                tint: tint,
                actionTitle: actionTitle,
                action: action
            )
        }

        toastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if !Task.isCancelled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    activeToast = nil
                }
            }
        }
    }

    private func dismissToast() {
        toastDismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeToast = nil
        }
    }

    private func selectNextItem() {
        guard !isSearchFocused else { return }
        let list = currentFilteredList
        guard !list.isEmpty else { return }
        if let current = selectedCoursework, let idx = list.firstIndex(where: { $0.id == current.id }) {
            let nextIdx = min(list.count - 1, idx + 1)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = list[nextIdx]
            }
            triggerHapticFeedback()
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = list.first
            }
            triggerHapticFeedback()
        }
    }

    private func selectPreviousItem() {
        guard !isSearchFocused else { return }
        let list = currentFilteredList
        guard !list.isEmpty else { return }
        if let current = selectedCoursework, let idx = list.firstIndex(where: { $0.id == current.id }) {
            let prevIdx = max(0, idx - 1)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = list[prevIdx]
            }
            triggerHapticFeedback()
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = list.last
            }
            triggerHapticFeedback()
        }
    }

    private func refreshData() {
        self.courses = ClassroomStorage.shared.loadCourses()
        self.allCoursework = ClassroomStorage.shared.loadCoursework()
        if let current = selectedCoursework, !allCoursework.contains(where: { $0.id == current.id }) {
            autoSelectFirstItem()
        }
    }

    private func selectItem(_ item: Coursework) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            self.selectedCoursework = item
        }
        triggerHapticFeedback()
    }

    private func autoSelectFirstItem() {
        let list = currentFilteredList
        if let first = list.first {
            self.selectedCoursework = first
        } else {
            self.selectedCoursework = nil
        }
    }

    private func toggleCompletion(for item: Coursework) {
        var all = ClassroomStorage.shared.loadCoursework()
        if let index = all.firstIndex(where: { $0.id == item.id }) {
            let wasTurnedIn = (all[index].status == .turnedIn)
            let newStatus: SubmissionStatus = wasTurnedIn ? .pending : .turnedIn
            all[index].status = newStatus
            ClassroomStorage.shared.saveCoursework(all)

            triggerHapticFeedback()

            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                refreshData()
                if selectedCoursework?.id == item.id {
                    selectedCoursework = all[index]
                }
            }

            let itemCourse = all[index].courseName
            let itemTitle = all[index].title
            let currentItem = all[index]

            if newStatus == .turnedIn {
                showToast(
                    title: "Đã hoàn thành bài tập!",
                    subtitle: "\(itemCourse): \(itemTitle)",
                    icon: "checkmark.circle.fill",
                    tint: .green,
                    actionTitle: "Hoàn tác",
                    action: { [self] in
                        toggleCompletion(for: currentItem)
                    }
                )
            } else {
                showToast(
                    title: "Đã chuyển về chưa nộp",
                    subtitle: "\(itemCourse): \(itemTitle)",
                    icon: "arrow.uturn.backward.circle.fill",
                    tint: .orange
                )
            }
        }
    }

    private func copyToClipboard(_ text: String, title: String? = nil) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        triggerHapticFeedback()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            copyFeedbackMessage = "Đã sao chép!"
        }
        showToast(
            title: "Đã sao chép nội dung bài tập",
            subtitle: title ?? "Đã lưu vào bộ nhớ tạm (Clipboard)",
            icon: "doc.on.doc.fill",
            tint: .blue
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.copyFeedbackMessage = nil
            }
        }
        #endif
    }

    private func startGoogleLogin() {
        isSigningIn = true
        errorMessage = nil
        Task {
            do {
                try await authService.startSignIn()
                await apiService.syncAll()
                refreshData()
                autoSelectFirstItem()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }

    private static let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'tháng' M, yyyy"
        return formatter
    }()

    private func formattedCurrentDate() -> String {
        Self.headerDateFormatter.string(from: Date()).capitalized
    }
}

public struct ToastMessage: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let tint: Color
    public var actionTitle: String? = nil
    public var action: (() -> Void)? = nil

    public static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

private struct FloatingToastHUD: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(toast.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                if let sub = toast.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let actionTitle = toast.actionTitle, let action = toast.action {
                Button(actionTitle) {
                    action()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .tint(toast.tint)
                .font(.system(size: 11, weight: .semibold))
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.24), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(toast.tint.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct AssignmentListRow: View {
    let item: Coursework
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false

    var isTurnedIn: Bool {
        item.status == .turnedIn || item.status == .returned
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        checkmarkBounce = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        checkmarkBounce = false
                    }
                    onToggleCompletion()
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 26)

                        if isTurnedIn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.green)
                                .background(Circle().fill(Color.white).padding(1))
                                .offset(x: 3, y: 3)
                                .scaleEffect(checkmarkBounce ? 1.3 : 1.0)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(checkmarkBounce ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)
                .help(isTurnedIn ? "Đã nộp bài (Space hoặc bấm để hoàn tác)" : "Chưa nộp bài (Space hoặc bấm để đánh dấu hoàn thành)")

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isTurnedIn ? .secondary : .primary)
                        .strikethrough(isTurnedIn)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: 0.2), value: isTurnedIn)

                    Text(item.courseName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                DueBadgeView(item: item, compact: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.12) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.35) : (isHovered ? Color.primary.opacity(0.08) : Color.clear), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct MetaInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isHovered ? 0.10 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(isHovered ? 0.30 : 0.18), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct AssignmentListEmptyView: View {
    let filter: ContentView.AppFilterCategory
    let isSearching: Bool
    let searchText: String
    let onClearSearch: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [emptyTint.opacity(0.22), emptyTint.opacity(0.0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: emptyIcon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(emptyTint)
            }

            VStack(spacing: 4) {
                Text(emptyTitle)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(emptySubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if isSearching {
                Button("Xóa tìm kiếm") {
                    onClearSearch()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyIcon: String {
        if isSearching { return "magnifyingglass" }
        switch filter {
        case .tomorrow: return "calendar.badge.checkmark"
        case .todayAndTomorrow: return "sun.max"
        case .allUpcoming: return "tray"
        case .past: return "checkmark.seal.fill"
        case .completed: return "doc.text.magnifyingglass"
        case .widgetPreview: return "macwindow"
        }
    }

    private var emptyTint: Color {
        if isSearching { return .blue }
        switch filter {
        case .tomorrow: return .blue
        case .todayAndTomorrow: return .orange
        case .allUpcoming: return .blue
        case .past: return .green
        case .completed: return .secondary
        case .widgetPreview: return .purple
        }
    }

    private var emptyTitle: String {
        if isSearching { return "Không tìm thấy bài tập nào" }
        switch filter {
        case .tomorrow: return "Không có bài tập cho ngày mai"
        case .todayAndTomorrow: return "Không có bài tập hôm nay & mai"
        case .allUpcoming: return "Không có bài tập sắp tới"
        case .past: return "Không có bài tập quá hạn!"
        case .completed: return "Chưa có bài tập hoàn thành"
        case .widgetPreview: return "Xem trước Widget"
        }
    }

    private var emptySubtitle: String {
        if isSearching {
            return "Không có bài tập nào khớp với từ khóa \"\(searchText)\"."
        }
        switch filter {
        case .tomorrow:
            return "Tất cả bài tập ngày mai đã hoàn thành hoặc chưa có bài mới."
        case .todayAndTomorrow:
            return "Bạn đã làm xong mọi việc cần nộp hôm nay và ngày mai. Hãy nghỉ ngơi nhé!"
        case .allUpcoming:
            return "Hiện không có bài tập nào trong danh sách theo dõi."
        case .past:
            return "Tuyệt vời! Bạn đang duy trì tiến độ hoàn hảo, không có bài tập nào bị trễ."
        case .completed:
            return "Các bài tập bạn đã nộp hoặc đánh dấu hoàn thành sẽ xuất hiện tại đây."
        case .widgetPreview:
            return "Kéo thả widget ra màn hình chính để theo dõi nhanh bài tập."
        }
    }
}

private struct HomeworkReaderEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.16), Color.blue.opacity(0.0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "book.pages")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(Color.blue)
            }

            VStack(spacing: 6) {
                Text("Chọn một bài tập từ danh sách bên trái")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Toàn bộ nội dung, hướng dẫn và hạn nộp chi tiết sẽ hiển thị tại đây")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            HStack(spacing: 8) {
                KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
                KeyboardShortcutPill(shortcut: "⌘O", label: "Mở Classroom")
                KeyboardShortcutPill(shortcut: "⌘F", label: "Tìm kiếm")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

private struct KeyboardShortcutPill: View {
    let shortcut: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(shortcut)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

private struct GuideStepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 19, height: 19)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.10, green: 0.45, blue: 0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.9))
        }
    }
}
