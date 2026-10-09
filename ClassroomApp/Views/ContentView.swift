import SwiftUI
import WidgetKit
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public struct SpringPressButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

public struct AppLogoView: View {
    public var size: CGFloat

    public init(size: CGFloat = 84) {
        self.size = size
    }

    public var body: some View {
        Group {
            #if os(macOS)
            if let nsImg = NSApplication.shared.applicationIconImage {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let assetImg = NSImage(named: "AppLogo") {
                Image(nsImage: assetImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallbackIcon
            }
            #else
            if let uiImg = UIImage(named: "AppLogo") ?? UIImage(named: "AppIcon") {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallbackIcon
            }
            #endif
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.223, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    private var fallbackIcon: some View {
        ZStack {
            ChunkyTheme.skyGradient
            ChunkyEmberCharacterView(emotion: .normal, size: size * 0.72)
        }
        .frame(width: size, height: size)
    }
}

public struct ContentView: View {
    @StateObject private var authService = GoogleOAuthService.shared
    @StateObject private var apiService = ClassroomAPIService.shared
    @StateObject private var updateService = AppUpdateService.shared

    @State private var courses: [Course] = []
    @State private var allCoursework: [Coursework] = []
    @State private var buckets = CourseworkBuckets()
    @State private var selectedFilter: AppFilterCategory = .tomorrow
    @State private var selectedCourseworkIds: Set<String> = []
    @State private var selectedCoursework: Coursework? = nil
    @State private var selectedPreviewFamily: WidgetPreviewFamily = .medium
    @State private var useSampleDataForPreview: Bool = false
    @State private var showSettingsModal: Bool = false
    @State private var clientIdInput: String = ""
    @State private var clientSecretInput: String = ""
    @State private var isSigningIn: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isDemoMode: Bool = false
    @State private var showAdvancedOAuthConfig: Bool = false
    @State private var welcomeAppeared: Bool = false
    @State private var floatingPhase: CGFloat = 0
    @State private var searchText: String = ""
    @State private var copyFeedbackMessage: String? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var activeToast: ToastMessage? = nil
    @State private var toastDismissTask: Task<Void, Never>? = nil
    @State private var syncRotationAngle: Double = 0
    @State private var hasInitialLoadHappened: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var liquidGlassNamespace
    @State private var showCompactCourseFilterSheet: Bool = false
    @State private var showMobileDetailSheet: Bool = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    private var isLandscapePhone: Bool {
        verticalSizeClass == .compact
    }
    #endif

    public enum AppFilterCategory: String, CaseIterable, Identifiable {
        case tomorrow = "Báo bài Ngày mai"
        case todayAndTomorrow = "Hôm nay & Ngày mai"
        case allUpcoming = "Tất cả sắp tới"
        case past = "Đã quá hạn"
        case completed = "Đã hoàn thành"
        case widgetPreview = "Xem trước Widget"

        public var id: String { rawValue }

        public var icon: String {
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

    public enum WidgetPreviewFamily: String, CaseIterable, Identifiable {
        case small = "Nhỏ"
        case medium = "Vừa"
        case large = "Lớn"
        public var id: String { rawValue }
    }

    public struct CourseworkBuckets {
        public var tomorrow: [Coursework]
        public var today: [Coursework]
        public var laterUpcoming: [Coursework]
        public var past: [Coursework]
        public var noDueDate: [Coursework]
        public var completed: [Coursework]

        public let todayAndTomorrow: [Coursework]
        public let allUpcoming: [Coursework]
        public var widgetItems: [Coursework] { tomorrow }

        public let tomorrowPendingCount: Int
        public let todayAndTomorrowPendingCount: Int
        public let allUpcomingPendingCount: Int
        public let pastPendingCount: Int
        public let completedCount: Int

        public init(
            tomorrow: [Coursework] = [],
            today: [Coursework] = [],
            laterUpcoming: [Coursework] = [],
            past: [Coursework] = [],
            noDueDate: [Coursework] = [],
            completed: [Coursework] = []
        ) {
            self.tomorrow = tomorrow
            self.today = today
            self.laterUpcoming = laterUpcoming
            self.past = past
            self.noDueDate = noDueDate
            self.completed = completed
            self.todayAndTomorrow = today + tomorrow
            self.allUpcoming = today + tomorrow + laterUpcoming + noDueDate

            let tomorrowPending = tomorrow.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let todayPending = today.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let laterPending = laterUpcoming.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let noDuePending = noDueDate.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }

            self.tomorrowPendingCount = tomorrowPending
            self.todayAndTomorrowPendingCount = todayPending + tomorrowPending
            self.allUpcomingPendingCount = todayPending + tomorrowPending + laterPending + noDuePending
            self.pastPendingCount = past.count
            self.completedCount = completed.count
        }
    }

    public init() {}

    private func recomputeBuckets() {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        let allCourseIds = Set(courses.map(\.id))
        let itemsMatchCourses = allCoursework.contains { allCourseIds.contains($0.courseId) }

        var tomorrows: [Coursework] = []
        var todays: [Coursework] = []
        var laters: [Coursework] = []
        var pasts: [Coursework] = []
        var noDates: [Coursework] = []
        var comp: [Coursework] = []

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
            return
        }

        for item in allCoursework {
            if itemsMatchCourses && !courses.isEmpty && !activeCourseIds.contains(item.courseId) {
                continue
            }

            if item.isCompleted {
                comp.append(item)
            }

            guard let dueDate = item.dueDate else {
                noDates.append(item)
                continue
            }

            if dueDate < now {
                if !item.isCompleted {
                    pasts.append(item)
                }
            } else if dueDate < startOfTomorrow {
                todays.append(item)
            } else if dueDate < startOfDayAfter {
                tomorrows.append(item)
            } else {
                laters.append(item)
            }
        }

        let sortWithPendingFirstAscending: (Coursework, Coursework) -> Bool = {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            switch ($0.dueDate, $1.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 < d2 }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }

        let dueDateDescending: (Coursework, Coursework) -> Bool = {
            switch ($0.dueDate, $1.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 > d2 }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }

        tomorrows.sort(by: sortWithPendingFirstAscending)
        todays.sort(by: sortWithPendingFirstAscending)
        laters.sort(by: sortWithPendingFirstAscending)
        pasts.sort(by: sortWithPendingFirstAscending)
        comp.sort(by: dueDateDescending)
        noDates.sort(by: sortWithPendingFirstAscending)

        self.buckets = CourseworkBuckets(
            tomorrow: tomorrows,
            today: todays,
            laterUpcoming: laters,
            past: pasts,
            noDueDate: noDates,
            completed: comp
        )
    }

    private var itemsForPreview: [Coursework] {
        if useSampleDataForPreview {
            return RisoMockData.fourTasks
        }
        let realItems = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        if !realItems.isEmpty {
            return realItems
        }
        if ClassroomStorage.shared.hasUserLoggedIn {
            return []
        }
        return RisoMockData.fourTasks
    }

    private var baseFilteredList: [Coursework] {
        switch selectedFilter {
        case .tomorrow:
            return buckets.tomorrow
        case .todayAndTomorrow:
            return buckets.todayAndTomorrow
        case .allUpcoming:
            return buckets.allUpcoming
        case .past:
            return buckets.past
        case .completed:
            return buckets.completed
        case .widgetPreview:
            return []
        }
    }

    private var currentFilteredList: [Coursework] {
        let baseList = baseFilteredList
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return baseList }

        let cleanQuery = query.normalizedForVietnameseSearch()
        return baseList.filter { item in
            item.searchIndex.contains(cleanQuery)
        }
    }

    private func categorizedSections(for list: [Coursework]) -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return (
                todays: buckets.today,
                tomorrows: buckets.tomorrow,
                laters: selectedFilter == .allUpcoming ? buckets.laterUpcoming : [],
                noDueDates: selectedFilter == .allUpcoming ? buckets.noDueDate : []
            )
        } else {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
                  let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday) else {
                return ([], [], [], [])
            }

            var todays: [Coursework] = []
            var tomorrows: [Coursework] = []
            var laters: [Coursework] = []
            var noDueDates: [Coursework] = []

            for item in list {
                guard let dueDate = item.dueDate else {
                    if selectedFilter == .allUpcoming { noDueDates.append(item) }
                    continue
                }
                if dueDate < startOfTomorrow {
                    todays.append(item)
                } else if dueDate < startOfDayAfter {
                    tomorrows.append(item)
                } else if selectedFilter == .allUpcoming {
                    laters.append(item)
                }
            }

            return (todays, tomorrows, laters, noDueDates)
        }
    }

    public var body: some View {
        Group {
            if authService.isAuthenticated || isDemoMode {
                mainAppContainer
            } else {
                welcomeLoginView
            }
        }
        .onAppear {
            clientIdInput = authService.configuredClientId
            clientSecretInput = authService.configuredClientSecret
            refreshData()
            hasInitialLoadHappened = true

            if authService.isAuthenticated {
                Task {
                    await Task.yield()
                    await apiService.syncAll()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        refreshData()
                    }
                }
            }
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                await updateService.checkForUpdates()
            }
        }
        .onChange(of: selectedFilter) {
            if selectedFilter == .past && buckets.past.isEmpty {
                selectedFilter = .tomorrow
            }
            autoSelectFirstItem()
        }
        .onChange(of: searchText) {
            let list = currentFilteredList
            if let current = selectedCoursework, list.contains(where: { $0.id == current.id }) {
                // Keep selected coursework if it matches query
            } else if let first = list.first {
                selectedCoursework = first
                selectedCourseworkIds = [first.id]
            } else {
                selectedCoursework = nil
                selectedCourseworkIds.removeAll()
            }
        }
        #if os(iOS)
        .onChange(of: selectedCoursework) {
            if horizontalSizeClass == .compact && selectedCoursework == nil {
                showMobileDetailSheet = false
            }
        }
        #endif
        #if os(iOS)
        .onChange(of: verticalSizeClass) {
            if verticalSizeClass == .compact {
                showMobileDetailSheet = false
                columnVisibility = .detailOnly
                autoSelectFirstItem()
            } else {
                columnVisibility = .all
            }
        }
        #endif
        .onChange(of: scenePhase) {
            guard hasInitialLoadHappened, scenePhase == .active else { return }
            refreshData()
            if authService.isAuthenticated {
                let shouldSync: Bool
                if let lastSync = ClassroomStorage.shared.loadLastSyncTime() {
                    shouldSync = Date().timeIntervalSince(lastSync) > 300
                } else {
                    shouldSync = true
                }
                if shouldSync {
                    Task {
                        await apiService.syncAll()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            refreshData()
                        }
                    }
                }
            }
        }
        .onChange(of: authService.authErrorMessage) {
            if let msg = authService.authErrorMessage {
                showToast(
                    title: "Xác thực Google",
                    subtitle: msg,
                    icon: "exclamationmark.triangle.fill",
                    tint: .red
                )
            }
        }
        .onChange(of: authService.isAuthenticated) {
            if authService.isAuthenticated {
                Task {
                    await apiService.syncAll()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        refreshData()
                    }
                }
            } else {
                refreshData()
                autoSelectFirstItem()
            }
        }
        .sheet(isPresented: $showSettingsModal) {
            settingsSheetView
        }
    }

    @ViewBuilder
    private var welcomeLoginView: some View {
        ZStack {
            Color.platformWindowBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                AppLogoView(size: 88)
                    .offset(y: floatingPhase)
                    .opacity(welcomeAppeared ? 1 : 0)
                    .scaleEffect(welcomeAppeared ? 1 : 0.85)

                VStack(spacing: 6) {
                    Text("Classroom Tracker")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Theo dõi bài tập Google Classroom")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .opacity(welcomeAppeared ? 1 : 0)
                .offset(y: welcomeAppeared ? 0 : 8)

                if let err = errorMessage ?? authService.authErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .frame(maxWidth: 380)
                }

                VStack(spacing: 12) {
                    Button {
                        triggerHapticFeedback()
                        startGoogleLogin()
                    } label: {
                        HStack(spacing: 10) {
                            if isSigningIn {
                                ProgressView()
                                    .controlSize(.small)
                                #if os(macOS)
                                    .colorScheme(.dark)
                                #endif
                                Text("Đang kết nối Google...")
                                    .font(.system(size: 15, weight: .semibold))
                            } else {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Đăng nhập bằng Google")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(SpringPressButtonStyle())
                    .disabled(isSigningIn)

                    Button {
                        triggerHapticFeedback()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            ClassroomStorage.shared.populateMockDataManually()
                            refreshData()
                            isDemoMode = true
                            autoSelectFirstItem()
                        }
                    } label: {
                        Text("Xem thử dữ liệu mẫu")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(SpringPressButtonStyle())
                }
                .frame(maxWidth: 320)
                .opacity(welcomeAppeared ? 1 : 0)
                .offset(y: welcomeAppeared ? 0 : 12)

                DisclosureGroup(
                    isExpanded: $showAdvancedOAuthConfig,
                    content: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ứng dụng đã có sẵn Google Client ID. Bạn chỉ cần cấu hình nếu muốn dùng Client ID riêng.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Client ID:")
                                    .font(.system(size: 11.5, weight: .medium))
                                TextField("Google Client ID", text: $clientIdInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11.5, design: .monospaced))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Client Secret (Tùy chọn):")
                                    .font(.system(size: 11.5, weight: .medium))
                                SecureField("Google Client Secret", text: $clientSecretInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11.5, design: .monospaced))
                            }

                            HStack {
                                Button("Mặc định") {
                                    clientIdInput = GoogleOAuthService.bundledClientId
                                    clientSecretInput = GoogleOAuthService.bundledClientSecret
                                    authService.configuredClientId = GoogleOAuthService.bundledClientId
                                    authService.configuredClientSecret = GoogleOAuthService.bundledClientSecret
                                }
                                .font(.system(size: 11.5))

                                Spacer()

                                Button("Lưu") {
                                    authService.configuredClientId = clientIdInput
                                    authService.configuredClientSecret = clientSecretInput
                                    showToast(title: "Đã lưu cấu hình OAuth", icon: "checkmark.circle.fill", tint: .green)
                                }
                                .font(.system(size: 11.5, weight: .semibold))
                            }
                        }
                        .padding(.top, 6)
                    },
                    label: {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape")
                            Text("Cài đặt OAuth nâng cao")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                    }
                )
                .frame(maxWidth: 380)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.platformControlBackground.opacity(0.5))
                )
                .opacity(welcomeAppeared ? 1 : 0)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 460)
        #endif
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                welcomeAppeared = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                floatingPhase = 5
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = activeToast {
                FloatingToastHUD(toast: toast, onDismiss: { dismissToast() })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 12)),
                        removal: .opacity.combined(with: .scale(scale: 0.92))
                    ))
                    .zIndex(100)
            }
        }
    }

    @ViewBuilder
    private var mainAppContainer: some View {
        #if os(iOS)
        GeometryReader { outerGeometry in
            let isCompact = (horizontalSizeClass == .compact) || (outerGeometry.size.width < 660)
            if isCompact {
                compactAppView
            } else {
                splitViewContainer
            }
        }
        #else
        splitViewContainer
        #endif
    }

    #if os(iOS)
    @ViewBuilder
    private var compactAppView: some View {
        NavigationStack {
            detailMasterView(isCompact: true)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    LiquidGlassBottomNavigationBar(
                        selectedFilter: $selectedFilter,
                        buckets: buckets,
                        glassNamespace: liquidGlassNamespace,
                        onSelect: { _ in
                            autoSelectFirstItem()
                        }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                }
        }
        .sheet(isPresented: $showCompactCourseFilterSheet) {
            compactCourseFilterSheetView
        }
    }

    private var compactCourseFilterSheetView: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(courses) { course in
                        CourseSelectionRow(
                            course: course,
                            onToggle: {
                                toggleCourse(courseId: course.id)
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
                            toggleAllCourses()
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Lọc môn học")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        showCompactCourseFilterSheet = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
    #endif

    @ViewBuilder
    private var splitViewContainer: some View {
        #if os(iOS)
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $preferredCompactColumn) {
            sidebarView
        } detail: {
            detailMasterView(isCompact: false)
        }
        .navigationSplitViewStyle(.balanced)
        #else
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            detailMasterView(isCompact: false)
                .frame(minWidth: 480)
        }
        .navigationSplitViewStyle(.balanced)
        #endif
    }

    private var sidebarView: some View {
        List(selection: Binding<AppFilterCategory?>(
            get: { selectedFilter },
            set: {
                if let val = $0 {
                    selectedFilter = val
                    #if os(iOS)
                    preferredCompactColumn = .detail
                    if isLandscapePhone {
                        columnVisibility = .detailOnly
                    }
                    #endif
                }
            }
        )) {
            if !authService.isAuthenticated {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            Text("Chế độ xem thử")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.purple)
                        }
                        Text("Đang dùng dữ liệu mẫu. Đăng nhập để đồng bộ bài tập.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Button {
                            startGoogleLogin()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                Text("Đăng nhập Google")
                            }
                            .font(.system(size: 11.5, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Danh mục báo bài") {
                sidebarCategoryRow(for: .tomorrow, count: buckets.tomorrowPendingCount)
                sidebarCategoryRow(for: .todayAndTomorrow, count: buckets.todayAndTomorrowPendingCount)
                sidebarCategoryRow(for: .allUpcoming, count: buckets.allUpcomingPendingCount)
                if buckets.past.count > 0 {
                    sidebarCategoryRow(for: .past, count: buckets.past.count)
                }
                sidebarCategoryRow(for: .completed, count: buckets.completed.count)
            }

            Section("Cấu hình Widget") {
                sidebarCategoryRow(for: .widgetPreview, count: nil)
            }

            Section {
                ForEach(courses) { course in
                    CourseSelectionRow(
                        course: course,
                        onToggle: {
                            toggleCourse(courseId: course.id)
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
                        toggleAllCourses()
                    }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Classroom")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        #endif
    }

    @ViewBuilder
    private func sidebarCategoryRow(for category: AppFilterCategory, count: Int?) -> some View {
        let isSelected = (selectedFilter == category)
        sidebarCategoryRowContent(for: category, count: count, isSelected: isSelected)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    selectedFilter = category
                }
                #if os(iOS)
                preferredCompactColumn = .detail
                if isLandscapePhone {
                    columnVisibility = .detailOnly
                }
                #endif
            }
            .tag(category)
    }

    private func sidebarCategoryRowContent(for category: AppFilterCategory, count: Int?, isSelected: Bool) -> some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.24) : categoryIconColor(category).opacity(0.12))
                    .frame(width: 24, height: 24)

                Image(systemName: category.icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : categoryIconColor(category))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
            }

            Text(category.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .lineLimit(1)

            Spacer()

            if let count, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 6.5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white : categoryBadgeBg(category))
                            .shadow(color: isSelected ? Color.black.opacity(0.12) : Color.clear, radius: 2, x: 0, y: 1)
                    )
                    .foregroundStyle(isSelected ? categoryIconColor(category) : categoryBadgeFg(category))
                    .scaleEffect(isSelected ? 1.06 : 1.0)
            }
        }
        .padding(.vertical, 2)
        .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isSelected)
    }

    private func categoryIconColor(_ category: AppFilterCategory) -> Color {
        switch category {
        case .tomorrow: return Color(red: 0.12, green: 0.52, blue: 0.95)
        case .todayAndTomorrow: return Color(red: 0.88, green: 0.48, blue: 0.06)
        case .allUpcoming: return Color(red: 0.38, green: 0.42, blue: 0.82)
        case .past: return Color(red: 0.86, green: 0.24, blue: 0.26)
        case .completed: return Color(red: 0.12, green: 0.62, blue: 0.35)
        case .widgetPreview: return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }

    private func categoryBadgeBg(_ category: AppFilterCategory) -> Color {
        categoryIconColor(category).opacity(0.12)
    }

    private func categoryBadgeFg(_ category: AppFilterCategory) -> Color {
        categoryIconColor(category)
    }

    @ViewBuilder
    private func detailMasterView(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            headerBarView

            if updateService.updateAvailable {
                updateBannerView
            }

            Divider()

            if selectedFilter == .widgetPreview {
                ScrollView {
                    widgetPreviewSection
                        #if os(iOS)
                        .padding(horizontalSizeClass == .compact ? 12 : 24)
                        #else
                        .padding(24)
                        #endif
                }
            } else {
                #if os(iOS)
                GeometryReader { geometry in
                    let isWide = geometry.size.width >= 560
                    if isWide {
                        let listWidth = min(350, max(260, geometry.size.width * 0.38))
                        HStack(spacing: 0) {
                            assignmentListPane(isWide: true)
                                .frame(width: listWidth)

                            Divider()

                            homeworkReaderPane
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        assignmentListPane(isWide: false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .sheet(isPresented: $showMobileDetailSheet) {
                    NavigationStack {
                        homeworkReaderPane
                            .navigationTitle("Chi tiết bài tập")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Xong") { showMobileDetailSheet = false }
                                }
                            }
                    }
                }
                #else
                GeometryReader { geometry in
                    let isWide = geometry.size.width >= 560
                    if isWide {
                        let listWidth = min(360, max(280, geometry.size.width * 0.38))
                        HStack(spacing: 0) {
                            assignmentListPane(isWide: true)
                                .frame(width: listWidth)

                            Divider()

                            homeworkReaderPane
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        assignmentListPane(isWide: false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .sheet(isPresented: $showMobileDetailSheet) {
                    NavigationStack {
                        homeworkReaderPane
                            .navigationTitle("Chi tiết bài tập")
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Xong") { showMobileDetailSheet = false }
                                }
                            }
                    }
                    .frame(minWidth: 420, minHeight: 460)
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationTitle(selectedFilter.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .overlay(alignment: .bottom) {
            if let toast = activeToast {
                FloatingToastHUD(toast: toast, onDismiss: { dismissToast() })
                    .padding(.horizontal, 16)
                    #if os(iOS)
                    .padding(.bottom, 36)
                    #else
                    .padding(.bottom, 22)
                    #endif
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.92))
                    ))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: activeToast)
        .background {
            if !showSettingsModal {
                Group {
                    Button("") { selectNextItem() }
                        .keyboardShortcut(.downArrow, modifiers: [.option])
                    Button("") { selectPreviousItem() }
                        .keyboardShortcut(.upArrow, modifiers: [.option])
                    Button("") { isSearchFocused = true }
                        .keyboardShortcut("f", modifiers: [.command])
                    Button("") { handleEscape() }
                        .keyboardShortcut(.escape, modifiers: [])
                    #if os(macOS)
                    Button("") {
                        if !isSearchFocused, let item = selectedCoursework {
                            toggleCompletion(for: item)
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    Button("") {
                        if !isSearchFocused, let item = selectedCoursework {
                            toggleCompletion(for: item)
                        }
                    }
                    .keyboardShortcut("d", modifiers: [.command])
                    #endif
                }
                .opacity(0)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                if !isCompact && (horizontalSizeClass == .compact || isLandscapePhone) {
                    Button {
                        if isLandscapePhone {
                            columnVisibility = .all
                        }
                        preferredCompactColumn = .sidebar
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Classroom")
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            #endif

            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        triggerHapticFeedback()
                        await apiService.syncAll()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            refreshData()
                        }
                        if let error = apiService.syncErrorMessage {
                            showToast(
                                title: "Đồng bộ thất bại",
                                subtitle: error,
                                icon: "exclamationmark.triangle.fill",
                                tint: .red
                            )
                        } else {
                            showToast(
                                title: "Đồng bộ hoàn tất!",
                                subtitle: "Đã cập nhật dữ liệu mới nhất từ Classroom",
                                icon: "arrow.triangle.2.circlepath",
                                tint: .blue
                            )
                        }
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
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            refreshData()
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

    @ViewBuilder
    private var headerBarView: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact || isLandscapePhone {
            mobileCompactHeaderBar
        } else {
            regularHeaderBar
        }
        #else
        regularHeaderBar
        #endif
    }

    #if os(iOS)
    private var mobileCompactHeaderBar: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.platformTextTertiary)
                Text(formattedCurrentDate())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.platformTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            Button {
                showCompactCourseFilterSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Lớp (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(Color.platformTextSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.platformControlBackground)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if selectedFilter == .widgetPreview {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Xem trước")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.purple.opacity(0.08))
                .clipShape(Capsule())
            } else {
                let pendingCount = currentFilteredList.filter { !$0.isCompleted }.count
                if pendingCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(categoryIconColor(selectedFilter))
                            .frame(width: 6, height: 6)
                        Text("\(pendingCount) bài cần nộp")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(categoryIconColor(selectedFilter))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(categoryIconColor(selectedFilter).opacity(0.09))
                    .clipShape(Capsule())
                } else if !currentFilteredList.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Đã nộp tất cả")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.10))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.platformWindowBackground)
    }
    #endif

    private var regularHeaderBar: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(categoryIconColor(selectedFilter).opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: selectedFilter.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(categoryIconColor(selectedFilter))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedFilter.rawValue)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.platformTextPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.platformTextTertiary)
                        Text(formattedCurrentDate())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.platformTextSecondary)
                    }
                }
            }

            Spacer()

            if selectedFilter == .widgetPreview {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.purple)
                    Text("Cấu hình & Xem trước Widget")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.purple)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(Color.purple.opacity(0.08))
                .clipShape(Capsule())
            } else {
                let pendingCount = currentFilteredList.filter { !$0.isCompleted }.count
                if pendingCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(categoryIconColor(selectedFilter))
                            .frame(width: 6, height: 6)
                        Text("\(pendingCount) bài cần nộp")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(categoryIconColor(selectedFilter))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(categoryIconColor(selectedFilter).opacity(0.09))
                    .clipShape(Capsule())
                } else if !currentFilteredList.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Đã nộp tất cả")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.10))
                    .clipShape(Capsule())
                }
            }

            if authService.isAuthenticated {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.blue)
                    Text(authService.currentUserEmail ?? "Đã kết nối")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.platformTextSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.platformControlBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.platformCardBorder, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.platformWindowBackground)
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
        .background(Color.blue.opacity(0.08))
    }

    private var searchPlaceholder: String {
        #if os(macOS)
        return "Tìm kiếm bài tập... (⌘F)"
        #else
        return "Tìm kiếm bài tập..."
        #endif
    }

    private func assignmentListPane(isWide: Bool = true) -> some View {
        let list = currentFilteredList
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(isSearchFocused ? .blue : Color.platformTextTertiary)

                TextField(searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
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
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.platformTextTertiary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    #if os(macOS)
                    if !isSearchFocused {
                        Text("⌘F")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.platformTextTertiary)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(Color.platformSubtleFill)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    #endif
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8.5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.platformControlBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSearchFocused ? Color.blue.opacity(0.50) : Color.platformCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isSearchFocused ? 0.04 : 0.015), radius: 3, x: 0, y: 1)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .animation(.easeInOut(duration: 0.15), value: isSearchFocused)

            if !searchText.isEmpty {
                HStack {
                    Text("Tìm thấy \(list.count) bài tập")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.platformTextSecondary)
                        .contentTransition(.numericText())
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            if selectedCourseworkIds.count > 1 {
                HStack(spacing: 8) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.blue)

                    Text("Đã chọn \(selectedCourseworkIds.count) bài tập")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.platformTextPrimary)

                    Spacer()

                    Button {
                        batchToggleCompletion(for: selectedCourseworkIds)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Đã nộp")
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.12, green: 0.62, blue: 0.35))
                    .controlSize(.small)

                    Button("Bỏ chọn") {
                        handleDeselectAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.platformCardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
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
                    },
                    onSwitchToUpcoming: {
                        selectedFilter = .allUpcoming
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if selectedFilter == .tomorrow {
                            ForEach(list) { item in
                                AssignmentListRow(
                                    item: item,
                                    isSelected: selectedCourseworkIds.contains(item.id),
                                    onSelect: { cmdPressed in
                                        handleItemTap(item, commandPressed: cmdPressed, isWide: isWide)
                                    },
                                    onToggleCompletion: {
                                        toggleCompletion(for: item)
                                    }
                                )
                                .equatable()
                            }
                        } else if selectedFilter == .todayAndTomorrow || selectedFilter == .allUpcoming {
                            let sections = categorizedSections(for: list)

                            if !sections.todays.isEmpty {
                                SectionHeaderPill(title: "HÔM NAY", count: sections.todays.count, icon: "clock.fill", color: Color(red: 0.95, green: 0.55, blue: 0.10))
                                ForEach(sections.todays) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCourseworkIds.contains(item.id),
                                        onSelect: { cmdPressed in handleItemTap(item, commandPressed: cmdPressed, isWide: isWide) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                    .equatable()
                                }
                            }

                            if !sections.tomorrows.isEmpty {
                                SectionHeaderPill(title: "NGÀY MAI", count: sections.tomorrows.count, icon: "calendar", color: Color(red: 0.12, green: 0.55, blue: 0.95))
                                ForEach(sections.tomorrows) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCourseworkIds.contains(item.id),
                                        onSelect: { cmdPressed in handleItemTap(item, commandPressed: cmdPressed, isWide: isWide) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                    .equatable()
                                }
                            }

                            if !sections.laters.isEmpty {
                                SectionHeaderPill(title: "SẮP TỚI", count: sections.laters.count, icon: "tray", color: .secondary)
                                ForEach(sections.laters) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCourseworkIds.contains(item.id),
                                        onSelect: { cmdPressed in handleItemTap(item, commandPressed: cmdPressed, isWide: isWide) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                    .equatable()
                                }
                            }

                            if !sections.noDueDates.isEmpty {
                                SectionHeaderPill(title: "KHÔNG CÓ HẠN", count: sections.noDueDates.count, icon: "questionmark.circle", color: .secondary)
                                ForEach(sections.noDueDates) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCourseworkIds.contains(item.id),
                                        onSelect: { cmdPressed in handleItemTap(item, commandPressed: cmdPressed, isWide: isWide) },
                                        onToggleCompletion: { toggleCompletion(for: item) }
                                    )
                                    .equatable()
                                }
                            }
                        } else {
                            ForEach(list) { item in
                                AssignmentListRow(
                                    item: item,
                                    isSelected: selectedCourseworkIds.contains(item.id),
                                    onSelect: { cmdPressed in
                                        handleItemTap(item, commandPressed: cmdPressed, isWide: isWide)
                                    },
                                    onToggleCompletion: {
                                        toggleCompletion(for: item)
                                    }
                                )
                                .equatable()
                            }
                        }
                    }
                    .padding(12)
                }
                .refreshable {
                    if authService.isAuthenticated {
                        await apiService.syncAll()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            refreshData()
                        }
                    }
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                #endif
            }
        }
        .background(Color.platformWindowBackground)
    }

    private var homeworkReaderPane: some View {
        Group {
            if selectedCourseworkIds.count > 1 {
                let selectedItems = currentFilteredList.filter { selectedCourseworkIds.contains($0.id) }
                BatchSelectedSummaryView(
                    selectedItems: selectedItems,
                    onMarkAllDone: {
                        batchToggleCompletion(for: selectedCourseworkIds)
                    },
                    onDeselectAll: {
                        handleDeselectAll()
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

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .foregroundStyle(Color.blue)
                                    Text("NỘI DUNG & HƯỚNG DẪN BÀI TẬP")
                                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.platformTextSecondary)
                                }

                                Spacer()

                                if let desc = item.description, !desc.isEmpty {
                                    Button {
                                        copyToClipboard(desc, title: item.title)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 11))
                                                .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.blue)
                                            Text(copyFeedbackMessage ?? "Sao chép nội dung")
                                                .font(.system(size: 12.5, weight: .medium))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.blue)
                                    .help("Sao chép toàn bộ nội dung hướng dẫn")
                                }
                            }

                            if let desc = item.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 15.5, weight: .regular))
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
                                    Text("Bài tập này không có phần mô tả chi tiết từ giáo viên.")
                                        .font(.system(size: 14))
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

                        Spacer(minLength: 16)

                        Button {
                            triggerHapticFeedback()
                            openURL(item.destinationURL)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Mở bài tập trên Google Classroom để nộp bài")
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                #if os(macOS)
                                Text("(⌘O)")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.85)
                                #endif
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .keyboardShortcut("o", modifiers: [.command])
                        .help("Mở bài tập trực tiếp trên Google Classroom (⌘O)")
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
                if let desc = item.description, !desc.isEmpty {
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
            toggleCompletion(for: item)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: item.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
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
        }
        .buttonStyle(.bordered)
        #if os(iOS)
        .controlSize(horizontalSizeClass == .compact ? .regular : .small)
        #else
        .controlSize(.small)
        #endif
        .help("Đánh dấu hoàn thành / Hoàn tác (Phím Space)")
    }

    @ViewBuilder
    private func readerCopyPromptButton(for item: Coursework, desc: String) -> some View {
        Button {
            copyToClipboard(desc, title: item.title)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: copyFeedbackMessage != nil ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(copyFeedbackMessage != nil ? Color.green : Color.secondary)
                Text(copyFeedbackMessage ?? "Sao chép đề")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .buttonStyle(.bordered)
        #if os(iOS)
        .controlSize(horizontalSizeClass == .compact ? .regular : .small)
        #else
        .controlSize(.small)
        #endif
        .keyboardShortcut("c", modifiers: [.command, .shift])
        .help("Sao chép đề bài vào bộ nhớ tạm (⌘⇧C)")
    }

    @ViewBuilder
    private func readerActionButtons(for item: Coursework) -> some View {
        HStack(spacing: 8) {
            readerToggleCompletionButton(for: item)
            if let desc = item.description, !desc.isEmpty {
                readerCopyPromptButton(for: item, desc: desc)
            }
        }
    }

    private var widgetPreviewSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Xem trước Widget trên màn hình")
                        .font(.headline)
                    Text("Widget sẽ hiển thị tương tự khi bạn thêm vào màn hình chính.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                #if os(iOS)
                if horizontalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Kích thước", selection: $selectedPreviewFamily) {
                            ForEach(WidgetPreviewFamily.allCases) { family in
                                Text(family.rawValue).tag(family)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Dùng dữ liệu mẫu", isOn: $useSampleDataForPreview)
                            .toggleStyle(.switch)
                            .font(.system(size: 13, weight: .medium))
                    }
                } else {
                    regularPreviewControls
                }
                #else
                regularPreviewControls
                #endif

                if !useSampleDataForPreview && !ClassroomStorage.shared.hasUserLoggedIn && ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true).isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Chưa đăng nhập (đang tự động dùng dữ liệu mẫu cho xem trước)")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }

                GeometryReader { cardGeometry in
                    let availableWidth = cardGeometry.size.width - 32
                    let previewWidth = min(325, max(250, availableWidth))
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

                        Group {
                            switch selectedPreviewFamily {
                            case .small:
                                SmallWidgetView(courseworkList: itemsForPreview)
                                    .frame(width: 155, height: 155)
                            case .medium:
                                MediumWidgetView(courseworkList: itemsForPreview)
                                    .frame(width: previewWidth, height: 155)
                            case .large:
                                let size = min(previewWidth, 325)
                                LargeWidgetView(courseworkList: itemsForPreview)
                                    .frame(width: size, height: size)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: selectedPreviewFamily == .large ? 390 : 220)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPreviewFamily)
            }
            #if os(iOS)
            .padding(horizontalSizeClass == .compact ? 14 : 20)
            #else
            .padding(20)
            #endif
            .background(Color.platformControlBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.platformCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)

            desktopGuideCard
        }
    }

    private var regularPreviewControls: some View {
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
                #if os(macOS)
                .toggleStyle(.checkbox)
                #else
                .toggleStyle(.switch)
                #endif
                .font(.system(size: 12))
                .lineLimit(1)
                .fixedSize()
        }
    }

    private var desktopGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            #if os(iOS)
            HStack(spacing: 8) {
                Image(systemName: "apps.iphone")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Hướng dẫn đưa Widget ra Màn hình chính (iOS)")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 9) {
                GuideStepRow(step: "1", text: "Chạm và giữ vào một vùng trống trên Màn hình chính cho đến khi các ứng dụng rung rinh.")
                GuideStepRow(step: "2", text: "Nhấn vào nút '+' ở góc trên cùng bên trái màn hình.")
                GuideStepRow(step: "3", text: "Tìm kiếm 'Classroom' trong danh sách tiện ích.")
                GuideStepRow(step: "4", text: "Chọn kích thước widget mong muốn (Nhỏ, Vừa, Lớn) và nhấn 'Thêm tiện ích'!")
            }
            #else
            HStack(spacing: 8) {
                Image(systemName: "macbook.and.iphone")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Hướng dẫn đưa Widget ra màn hình Desktop (macOS)")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 9) {
                GuideStepRow(step: "1", text: "Click chuột phải vào bất kỳ vị trí trống nào trên màn hình Desktop của bạn.")
                GuideStepRow(step: "2", text: "Chọn 'Chỉnh sửa tiện ích...' (Edit Widgets...).")
                GuideStepRow(step: "3", text: "Tìm kiếm 'Classroom Hôm nay & Ngày mai' trong danh sách tiện ích bên dưới.")
                GuideStepRow(step: "4", text: "Kéo thả widget với kích thước mong muốn (Nhỏ, Vừa, Lớn) ra màn hình chính!")
            }
            #endif
        }
        .padding(20)
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
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
                    Label("Cấu hình Google Cloud OAuth", systemImage: "key.fill")
                } footer: {
                    #if os(iOS)
                    Text("Lấy Client ID từ Google Cloud Console (loại ứng dụng iOS hoặc Web). Ứng dụng sẽ tự động chuyển hướng xác thực an toàn.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    #else
                    Text("Lấy Client ID từ Google Cloud Console (loại ứng dụng iOS/macOS hoặc Desktop). Ứng dụng hỗ trợ cả xác thực native an toàn và loopback.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    #endif
                }

                Section {
                    Button("Nạp lại dữ liệu mẫu (Mock Data hôm nay & mai)") {
                        ClassroomStorage.shared.saveCourses(ClassroomStorage.mockCourses)
                        ClassroomStorage.shared.saveCoursework(ClassroomStorage.mockCoursework)
                        refreshData()
                        autoSelectFirstItem()
                        showSettingsModal = false
                        showToast(
                            title: "Đã nạp lại dữ liệu mẫu!",
                            subtitle: "Bao gồm các bài tập mẫu cho hôm nay & ngày mai",
                            icon: "sparkles",
                            tint: .purple
                        )
                    }
                } header: {
                    Label("Dữ liệu thử nghiệm", systemImage: "sparkles")
                }

                Section {
                    HStack {
                        Text("Phiên bản hiện tại:")
                        Spacer()
                        Text("v\(updateService.latestVersion)")
                            .foregroundStyle(.secondary)
                    }

                    #if os(macOS)
                    TextField("GitHub Token (dành cho repo riêng tư)", text: Binding(
                        get: { updateService.githubToken },
                        set: { updateService.githubToken = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    #endif

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
                } header: {
                    Label("Cập nhật ứng dụng", systemImage: "arrow.triangle.2.circlepath")
                }

                if authService.isAuthenticated {
                    Section {
                        HStack {
                            Text("Email:")
                            Spacer()
                            Text(authService.currentUserEmail ?? "Không rõ")
                                .foregroundStyle(.secondary)
                        }

                        Button("Đăng xuất", role: .destructive) {
                            authService.signOut()
                            isDemoMode = false
                            refreshData()
                            autoSelectFirstItem()
                            showSettingsModal = false
                        }
                    } header: {
                        Label("Tài khoản hiện tại", systemImage: "person.crop.circle")
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
                    if authService.isAuthenticated {
                        Button("Lưu") {
                            authService.configuredClientId = clientIdInput
                            authService.configuredClientSecret = clientSecretInput
                            showSettingsModal = false
                        }
                    } else {
                        Button("Lưu & Đăng nhập") {
                            authService.configuredClientId = clientIdInput
                            authService.configuredClientSecret = clientSecretInput
                            showSettingsModal = false
                            startGoogleLogin()
                        }
                        .disabled(clientIdInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            #if os(macOS)
            .frame(minWidth: 460, minHeight: 340)
            #endif
        }
    }

    private func triggerHapticFeedback() {
        PlatformHaptics.trigger()
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

    private func handleEscape() {
        if !searchText.isEmpty {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                searchText = ""
            }
        } else if !selectedCourseworkIds.isEmpty {
            handleDeselectAll()
        }
    }

    private func handleDeselectAll() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            selectedCourseworkIds.removeAll()
            selectedCoursework = nil
        }
    }

    private func selectNextItem() {
        guard !isSearchFocused else { return }
        let list = currentFilteredList
        guard !list.isEmpty else { return }
        if let current = selectedCoursework, let idx = list.firstIndex(where: { $0.id == current.id }) {
            let nextIdx = min(list.count - 1, idx + 1)
            let item = list[nextIdx]
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = item
                selectedCourseworkIds = [item.id]
            }
            triggerHapticFeedback()
        } else {
            if let first = list.first {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    selectedCoursework = first
                    selectedCourseworkIds = [first.id]
                }
                triggerHapticFeedback()
            }
        }
    }

    private func selectPreviousItem() {
        guard !isSearchFocused else { return }
        let list = currentFilteredList
        guard !list.isEmpty else { return }
        if let current = selectedCoursework, let idx = list.firstIndex(where: { $0.id == current.id }) {
            let prevIdx = max(0, idx - 1)
            let item = list[prevIdx]
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedCoursework = item
                selectedCourseworkIds = [item.id]
            }
            triggerHapticFeedback()
        } else {
            if let last = list.last {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    selectedCoursework = last
                    selectedCourseworkIds = [last.id]
                }
                triggerHapticFeedback()
            }
        }
    }

    private func refreshData() {
        self.courses = ClassroomStorage.shared.loadCourses()
        self.allCoursework = ClassroomStorage.shared.loadCoursework()
        recomputeBuckets()

        if let current = selectedCoursework, currentFilteredList.contains(where: { $0.id == current.id }) {
            if let updated = allCoursework.first(where: { $0.id == current.id }) {
                self.selectedCoursework = updated
            }
        } else {
            autoSelectFirstItem()
        }
    }

    private func autoSelectFirstItem() {
        let list = currentFilteredList
        if let first = list.first {
            self.selectedCoursework = first
            self.selectedCourseworkIds = [first.id]
        } else {
            self.selectedCoursework = nil
            self.selectedCourseworkIds.removeAll()
        }
    }

    private func handleItemTap(_ item: Coursework, commandPressed: Bool = false, isWide: Bool = true) {
        triggerHapticFeedback()
        if !isWide {
            showMobileDetailSheet = true
        } else {
            showMobileDetailSheet = false
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            if commandPressed {
                if selectedCourseworkIds.contains(item.id) {
                    selectedCourseworkIds.remove(item.id)
                    if selectedCoursework?.id == item.id {
                        selectedCoursework = currentFilteredList.first(where: { selectedCourseworkIds.contains($0.id) })
                    }
                } else {
                    selectedCourseworkIds.insert(item.id)
                    selectedCoursework = item
                }
            } else {
                selectedCourseworkIds = [item.id]
                selectedCoursework = item
            }
        }
    }

    private func toggleCourse(courseId: String) {
        if let index = courses.firstIndex(where: { $0.id == courseId }) {
            courses[index].isSelectedForWidget.toggle()
            ClassroomStorage.shared.saveCourses(courses)
            refreshData()
            triggerHapticFeedback()
        }
    }

    private func toggleAllCourses() {
        let allSelected = courses.allSatisfy(\.isSelectedForWidget)
        let newValue = !allSelected
        for i in courses.indices {
            courses[i].isSelectedForWidget = newValue
        }
        ClassroomStorage.shared.saveCourses(courses)
        refreshData()
        triggerHapticFeedback()
    }

    private func batchToggleCompletion(for ids: Set<String>) {
        guard !ids.isEmpty else { return }
        triggerHapticFeedback()
        ClassroomStorage.shared.updateCourseworkStatuses(ids: ids, newStatus: .turnedIn)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            refreshData()
            selectedCourseworkIds.removeAll()
        }
        showToast(
            title: "Đã hoàn thành \(ids.count) bài tập!",
            icon: "checkmark.circle.fill",
            tint: .green
        )
    }

    private func toggleCompletion(for item: Coursework) {
        var all = ClassroomStorage.shared.loadCoursework()
        if let index = all.firstIndex(where: { $0.id == item.id }) {
            let wasCompleted = all[index].isCompleted
            let isOverdue = all[index].dueDate != nil && all[index].dueDate! < Date()
            let newStatus: SubmissionStatus = wasCompleted ? (isOverdue ? .late : .pending) : .turnedIn
            all[index].status = newStatus
            ClassroomStorage.shared.saveCoursework(all)

            triggerHapticFeedback()

            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                refreshData()
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
        PlatformClipboard.copy(text)
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
    }

    private func startGoogleLogin() {
        isSigningIn = true
        errorMessage = nil
        Task {
            do {
                try await authService.startSignIn()
                await apiService.syncAll()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    refreshData()
                }
                autoSelectFirstItem()
                if let syncErr = apiService.syncErrorMessage {
                    showToast(
                        title: "Đồng bộ sau đăng nhập",
                        subtitle: syncErr,
                        icon: "exclamationmark.triangle.fill",
                        tint: .orange
                    )
                } else {
                    showToast(
                        title: "Đăng nhập thành công!",
                        subtitle: "Đã kết nối tài khoản Google và nạp bài tập",
                        icon: "checkmark.circle.fill",
                        tint: .blue
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                showToast(
                    title: "Đăng nhập Google thất bại",
                    subtitle: error.localizedDescription,
                    icon: "exclamationmark.triangle.fill",
                    tint: .red
                )
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
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                if let sub = toast.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.platformTextSecondary)
                        .lineLimit(2)
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
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color.platformTextTertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toast.tint.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct CourseSelectionRow: View, Equatable {
    let course: Course
    let onToggle: () -> Void

    @State private var isHovered: Bool = false

    static func == (lhs: CourseSelectionRow, rhs: CourseSelectionRow) -> Bool {
        lhs.course == rhs.course
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: course.isSelectedForWidget ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(course.isSelectedForWidget ? Color.blue : Color.secondary.opacity(0.45))

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
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct SectionHeaderPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Spacer()

            Text("\(count) bài")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(color.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
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

private struct BatchSelectedSummaryView: View {
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

            HStack(spacing: 12) {
                Button {
                    onMarkAllDone()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Đánh dấu tất cả đã nộp")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.12, green: 0.62, blue: 0.35))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button("Bỏ chọn") {
                    onDeselectAll()
                }
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.platformWindowBackground)
    }
}

private struct AssignmentListRow: View, Equatable {
    let item: Coursework
    let isSelected: Bool
    let onSelect: (Bool) -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false
    @Environment(\.openURL) private var openURL

    static func == (lhs: AssignmentListRow, rhs: AssignmentListRow) -> Bool {
        lhs.item == rhs.item && lhs.isSelected == rhs.isSelected
    }

    var isTurnedIn: Bool {
        item.isCompleted
    }

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Capsule()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(width: 3.5, height: 34)
                .animation(.easeInOut(duration: 0.15), value: isSelected)

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
                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 32)

                        if isTurnedIn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                                .background(Circle().fill(Color.white).padding(1))
                                .offset(x: 3, y: 3)
                                .scaleEffect(checkmarkBounce ? 1.3 : 1.0)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.3)
                                .background(Circle().fill(Color.platformControlBackground.opacity(0.85)))
                                .frame(width: 13, height: 13)
                                .offset(x: 2, y: 2)
                        }
                    }
                    .scaleEffect(checkmarkBounce ? 1.15 : 1.0)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .help(isTurnedIn ? "Đã nộp bài (Space hoặc bấm để hoàn tác)" : "Chưa nộp bài (Space hoặc bấm để đánh dấu hoàn thành)")

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: 0.2), value: isTurnedIn)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                            .frame(width: 6, height: 6)
                        Text(item.courseName)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                DueBadgeView(item: item, compact: true)
        }
        .padding(.horizontal, 10)
        #if os(iOS)
        .padding(.vertical, 10)
        .frame(minHeight: 58)
        #else
        .padding(.vertical, 8)
        #endif
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
        #if os(macOS)
        .shadow(
            color: Color.black.opacity(isSelected ? 0.04 : (isHovered ? 0.03 : 0.015)),
            radius: isSelected ? 4 : (isHovered ? 3 : 2),
            x: 0,
            y: 1
        )
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        #else
        .shadow(
            color: Color.black.opacity(isSelected ? 0.04 : 0.015),
            radius: isSelected ? 4 : 2,
            x: 0,
            y: 1
        )
        #endif
        .contentShape(Rectangle())
        .onTapGesture {
            #if os(macOS)
            let isCmd = NSEvent.modifierFlags.contains(.command)
            #else
            let isCmd = false
            #endif
            onSelect(isCmd)
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

private struct MetaInfoCard: View {
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
                        .frame(width: 26, height: 26)

                    Image(systemName: icon)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.platformTextSecondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHovered ? tint.opacity(0.24) : Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.035 : 0.015), radius: isHovered ? 4 : 2, x: 0, y: 1)
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
    var onSwitchToUpcoming: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if !isSearching && (filter == .tomorrow || filter == .todayAndTomorrow) {
                ChunkyEmberCharacterView(emotion: .sleeping, size: 76)
                    .padding(.bottom, 2)
            } else if !isSearching && filter == .past {
                ChunkyEmberCharacterView(emotion: .celebrating, size: 76)
                    .padding(.bottom, 2)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [emptyTint.opacity(0.18), emptyTint.opacity(0.0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 54
                            )
                        )
                        .frame(width: 92, height: 92)

                    Image(systemName: emptyIcon)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(emptyTint)
                }
            }

            VStack(spacing: 6) {
                Text(emptyTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                Text(emptySubtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.platformTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(3.5)
            }

            if isSearching {
                Button("Xóa tìm kiếm") {
                    onClearSearch()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.top, 4)
            } else if (filter == .tomorrow || filter == .todayAndTomorrow), let onSwitchToUpcoming {
                Button {
                    onSwitchToUpcoming()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "tray")
                            .font(.system(size: 12))
                        Text("Xem tất cả bài tập sắp tới")
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
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
        case .tomorrow: return Color(red: 0.15, green: 0.65, blue: 0.45)
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
        case .tomorrow: return "Ngày mai không có bài tập"
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
            return "Tất cả bài tập ngày mai đã hoàn thành hoặc chưa có bài mới. Bạn có thể yên tâm nghỉ ngơi!"
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
                            colors: [Color.blue.opacity(0.14), Color.blue.opacity(0.0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "book.pages")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.blue)
            }

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
            HStack(spacing: 8) {
                KeyboardShortcutPill(shortcut: "↑ / ↓", label: "Chuyển bài")
                KeyboardShortcutPill(shortcut: "Space", label: "Đánh dấu nộp")
                KeyboardShortcutPill(shortcut: "⌘O", label: "Mở Classroom")
                KeyboardShortcutPill(shortcut: "⌘F", label: "Tìm kiếm")
                KeyboardShortcutPill(shortcut: "⌘R", label: "Đồng bộ")
            }
            .padding(.top, 8)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.platformWindowBackground)
    }
}

private struct KeyboardShortcutPill: View {
    let shortcut: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Text(shortcut)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.platformTextPrimary)
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
        }
    }
}

private struct GuideStepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.10, green: 0.45, blue: 0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.platformTextPrimary)
        }
    }
}

// MARK: - Bottom Navigation Bar

public struct LiquidGlassBottomNavigationBar: View {
    @Binding var selectedFilter: ContentView.AppFilterCategory
    let buckets: ContentView.CourseworkBuckets
    var glassNamespace: Namespace.ID
    let onSelect: (ContentView.AppFilterCategory) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private struct TabItem: Identifiable, Equatable {
        let category: ContentView.AppFilterCategory
        let shortTitle: String
        let icon: String
        let activeIcon: String
        let count: Int?

        var id: String { category.rawValue }

        static func == (lhs: TabItem, rhs: TabItem) -> Bool {
            lhs.category == rhs.category && lhs.count == rhs.count
        }
    }

    private var tabs: [TabItem] {
        var items: [TabItem] = [
            TabItem(
                category: .tomorrow,
                shortTitle: "Báo bài",
                icon: "calendar.badge.clock",
                activeIcon: "calendar.badge.clock",
                count: buckets.tomorrowPendingCount
            ),
            TabItem(
                category: .todayAndTomorrow,
                shortTitle: "Hôm nay",
                icon: "clock",
                activeIcon: "clock.fill",
                count: buckets.todayAndTomorrowPendingCount
            ),
            TabItem(
                category: .allUpcoming,
                shortTitle: "Sắp tới",
                icon: "tray",
                activeIcon: "tray.fill",
                count: buckets.allUpcomingPendingCount
            ),
        ]
        if buckets.past.count > 0 {
            items.append(
                TabItem(
                    category: .past,
                    shortTitle: "Quá hạn",
                    icon: "clock.badge.exclamationmark",
                    activeIcon: "clock.badge.exclamationmark.fill",
                    count: buckets.past.count
                )
            )
        }
        items.append(
            TabItem(
                category: .completed,
                shortTitle: "Đã xong",
                icon: "checkmark.seal",
                activeIcon: "checkmark.seal.fill",
                count: buckets.completed.count
            )
        )
        if buckets.past.count == 0 {
            items.append(
                TabItem(
                    category: .widgetPreview,
                    shortTitle: "Widget",
                    icon: "macwindow",
                    activeIcon: "macwindow.on.rectangle",
                    count: nil
                )
            )
        }
        return items
    }

    public init(
        selectedFilter: Binding<ContentView.AppFilterCategory>,
        buckets: ContentView.CourseworkBuckets,
        glassNamespace: Namespace.ID,
        onSelect: @escaping (ContentView.AppFilterCategory) -> Void
    ) {
        self._selectedFilter = selectedFilter
        self.buckets = buckets
        self.glassNamespace = glassNamespace
        self.onSelect = onSelect
    }

    public var body: some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            nativeGlassBar
        } else {
            fallbackGlassBar
        }
        #else
        fallbackGlassBar
        #endif
    }

    #if os(iOS)
    @available(iOS 26, *)
    private var nativeGlassBar: some View {
        GlassEffectContainer(spacing: 3) {
            HStack(spacing: 3) {
                ForEach(tabs) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: 520)
            .glassEffect(.regular, in: .capsule)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 18, x: 0, y: 7)
            .shadow(color: Color.primary.opacity(0.04), radius: 2, x: 0, y: 1)
        }
    }
    #endif

    private var fallbackGlassBar: some View {
        HStack(spacing: 3) {
            ForEach(tabs) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: 520)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.30),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 18, x: 0, y: 7)
                .shadow(color: Color.primary.opacity(0.04), radius: 2, x: 0, y: 1)
        }
    }

    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = (selectedFilter == tab.category)
        let tabColor = categoryColor(tab.category)

        Button {
            selectTab(tab.category)
        } label: {
            Group {
                if isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: tab.activeIcon)
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundStyle(tabColor)

                        Text(tab.shortTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(tabColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        if let count = tab.count, count > 0 {
                            Text(count > 99 ? "99+" : "\(count)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(tabColor))
                        }
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(tabColor.opacity(colorScheme == .dark ? 0.24 : 0.14))
                            .overlay {
                                Capsule()
                                    .stroke(tabColor.opacity(colorScheme == .dark ? 0.45 : 0.28), lineWidth: 1)
                            }
                            .matchedGeometryEffect(id: "liquidGlassActivePill", in: glassNamespace)
                    }
                } else {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.85))
                            .frame(width: 26, height: 26)

                        if let count = tab.count, count > 0 {
                            Text(count > 99 ? "99+" : "\(count)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(tabColor.opacity(0.88)))
                                .offset(x: 10, y: -7)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tab.category.rawValue))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func selectTab(_ category: ContentView.AppFilterCategory) {
        guard selectedFilter != category else { return }
        triggerFeedback()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
            selectedFilter = category
            onSelect(category)
        }
    }

    private func triggerFeedback() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func categoryColor(_ category: ContentView.AppFilterCategory) -> Color {
        switch category {
        case .tomorrow: return Color(red: 0.12, green: 0.52, blue: 0.95)
        case .todayAndTomorrow: return Color(red: 0.88, green: 0.48, blue: 0.06)
        case .allUpcoming: return Color(red: 0.38, green: 0.42, blue: 0.82)
        case .past: return Color(red: 0.86, green: 0.24, blue: 0.26)
        case .completed: return Color(red: 0.12, green: 0.62, blue: 0.35)
        case .widgetPreview: return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }
}
