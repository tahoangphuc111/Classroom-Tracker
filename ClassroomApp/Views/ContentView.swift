import SwiftUI
import WidgetKit
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

public struct SpringPressButtonStyle: ButtonStyle {
    public var scale: CGFloat
    public var pressedOpacity: CGFloat

    public init(scale: CGFloat = 0.98, pressedOpacity: CGFloat = 0.92) {
        self.scale = scale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

public struct SpringPressCardModifier: ViewModifier {
    public var scale: CGFloat
    public var isPressed: Bool

    public init(scale: CGFloat = 0.98, isPressed: Bool) {
        self.scale = scale
        self.isPressed = isPressed
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isPressed)
    }
}

public extension View {
    func springPressCard(isPressed: Bool, scale: CGFloat = 0.98) -> some View {
        modifier(SpringPressCardModifier(scale: scale, isPressed: isPressed))
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
            if let assetImg = NSImage(named: "AppLogo") ?? NSImage(named: "AppIcon") {
                Image(nsImage: assetImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let nsImg = NSApplication.shared.applicationIconImage {
                Image(nsImage: nsImg)
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
    @StateObject private var reminderService = EveningReminderService.shared

    @State private var courses: [Course] = []
    @State private var allCoursework: [Coursework] = []
    @State private var personalNotes: [PersonalNote] = []
    @State private var courseworkNoteEditingText: String = ""
    @State private var courseworkNoteToEditCourseworkId: String? = nil
    @State private var buckets = CourseworkBuckets()
    @State private var selectedFilter: AppFilterCategory = .tomorrow
    @State private var selectedSubjectFilter: String = "Tất cả"
    @State private var selectedCourseworkIds: Set<String> = []
    @State private var selectedCoursework: Coursework? = nil
    @State private var selectedPreviewFamily: WidgetPreviewFamily = .medium
    @State private var useSampleDataForPreview: Bool = false
    @State private var showSettingsModal: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    @State private var clientIdInput: String = ""
    @State private var clientSecretInput: String = ""
    @State private var isSigningIn: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isDemoMode: Bool = false
    @State private var showAdvancedOAuthConfig: Bool = false
    @State private var isAdvancedSettingsExpanded: Bool = false
    @State private var welcomeAppeared: Bool = false
    @State private var floatingPhase: CGFloat = 0
    @State private var searchText: String = ""
    @State private var copyFeedbackMessage: String? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var activeToast: ToastMessage? = nil
    @State private var toastDismissTask: Task<Void, Never>? = nil
    @State private var hasInitialLoadHappened: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
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
        case notes = "Ghi chú cá nhân"
        case widgetPreview = "Xem trước Widget"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .tomorrow: return "calendar.badge.clock"
            case .todayAndTomorrow: return "clock"
            case .allUpcoming: return "tray"
            case .past: return "clock.badge.exclamationmark"
            case .completed: return "checkmark.seal"
            case .notes: return "square.and.pencil"
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
        public var tomorrowStrict: [Coursework]
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
            tomorrowStrict: [Coursework] = [],
            today: [Coursework] = [],
            laterUpcoming: [Coursework] = [],
            past: [Coursework] = [],
            noDueDate: [Coursework] = [],
            completed: [Coursework] = []
        ) {
            self.tomorrow = tomorrow
            self.tomorrowStrict = tomorrowStrict.isEmpty ? tomorrow : tomorrowStrict
            self.today = today
            self.laterUpcoming = laterUpcoming
            self.past = past
            self.noDueDate = noDueDate
            self.completed = completed
            self.todayAndTomorrow = today + (tomorrowStrict.isEmpty ? tomorrow : tomorrowStrict)
            self.allUpcoming = today + (tomorrowStrict.isEmpty ? tomorrow : tomorrowStrict) + laterUpcoming + noDueDate

            let tomorrowPending = tomorrow.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let todayPending = today.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let laterPending = laterUpcoming.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let noDuePending = noDueDate.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }

            self.tomorrowPendingCount = tomorrowPending
            self.todayAndTomorrowPendingCount = todayPending + (tomorrowStrict.isEmpty ? tomorrowPending : tomorrowStrict.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) })
            self.allUpcomingPendingCount = todayPending + (tomorrowStrict.isEmpty ? tomorrowPending : tomorrowStrict.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }) + laterPending + noDuePending
            self.pastPendingCount = past.count
            self.completedCount = completed.count
        }
    }

    public init() {
        #if os(iOS)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        let itemAppearance = UITabBarItemAppearance()
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        #endif
    }

    private func recomputeBuckets() {
        let activeCourseIds = Set(courses.filter(\.isSelectedForWidget).map(\.id))
        let allCourseIds = Set(courses.map(\.id))
        let itemsMatchCourses = allCoursework.contains { allCourseIds.contains($0.courseId) }

        var tomorrowsStrict: [Coursework] = []
        var todays: [Coursework] = []
        var laters: [Coursework] = []
        var pasts: [Coursework] = []
        var noDates: [Coursework] = []
        var comp: [Coursework] = []

        let calendar = Calendar.autoupdatingCurrent
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
                continue
            }

            guard let dueDate = item.dueDate else {
                noDates.append(item)
                continue
            }

            if dueDate < now {
                pasts.append(item)
            } else if dueDate < startOfTomorrow {
                todays.append(item)
            } else if dueDate < startOfDayAfter {
                tomorrowsStrict.append(item)
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
                let titleOrder = $0.title.localizedStandardCompare($1.title)
                if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
                return $0.id < $1.id
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                let titleOrder = $0.title.localizedStandardCompare($1.title)
                if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
                return $0.id < $1.id
            }
        }

        let dueDateDescending: (Coursework, Coursework) -> Bool = {
            switch ($0.dueDate, $1.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 > d2 }
                let titleOrder = $0.title.localizedStandardCompare($1.title)
                if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
                return $0.id < $1.id
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                let titleOrder = $0.title.localizedStandardCompare($1.title)
                if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
                return $0.id < $1.id
            }
        }

        tomorrowsStrict.sort(by: sortWithPendingFirstAscending)
        todays.sort(by: sortWithPendingFirstAscending)
        laters.sort(by: sortWithPendingFirstAscending)
        pasts.sort(by: sortWithPendingFirstAscending)
        comp.sort(by: dueDateDescending)
        noDates.sort(by: sortWithPendingFirstAscending)

        let baoBaiItems = ClassroomStorage.shared.getTomorrowCoursework(items: allCoursework, courses: courses, includeCompleted: true)

        self.buckets = CourseworkBuckets(
            tomorrow: baoBaiItems,
            tomorrowStrict: tomorrowsStrict,
            today: todays,
            laterUpcoming: laters,
            past: pasts,
            noDueDate: noDates,
            completed: comp
        )

        if selectedSubjectFilter != "Tất cả" && !availableSubjectPills.contains(selectedSubjectFilter) {
            selectedSubjectFilter = "Tất cả"
        }
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

    private func baseFilteredList(for category: AppFilterCategory) -> [Coursework] {
        switch category {
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
        case .notes:
            return []
        case .widgetPreview:
            return []
        }
    }

    private func currentFilteredList(for category: AppFilterCategory) -> [Coursework] {
        var baseList = baseFilteredList(for: category)
        if category == .allUpcoming && selectedSubjectFilter != "Tất cả" {
            baseList = baseList.filter { item in
                SubjectArtHelper.badgeCode(for: item.courseName, title: item.title) == selectedSubjectFilter
            }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return baseList }

        let cleanQuery = query.normalizedForVietnameseSearch()
        let tokens = cleanQuery.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return baseList }

        let matchingItems = baseList.filter { item in
            tokens.allSatisfy { item.searchIndex.contains($0) }
        }
        return matchingItems.sorted { first, second in
            let score1 = first.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)
            let score2 = second.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)
            if score1 != score2 {
                return score1 > score2
            }
            return first < second
        }
    }

    private var baseFilteredList: [Coursework] {
        baseFilteredList(for: selectedFilter)
    }

    private var currentFilteredList: [Coursework] {
        currentFilteredList(for: selectedFilter)
    }

    private var availableSubjectPills: [String] {
        let subjects = Set(buckets.allUpcoming.map {
            SubjectArtHelper.badgeCode(for: $0.courseName, title: $0.title)
        }).sorted()
        return ["Tất cả"] + subjects
    }

    private func categorizedSections(for list: [Coursework], category: AppFilterCategory? = nil) -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
        let targetCategory = category ?? selectedFilter
        let isDefaultFilter = searchText.trimmingCharacters(in: .whitespaces).isEmpty && (targetCategory != .allUpcoming || selectedSubjectFilter == "Tất cả")
        if isDefaultFilter {
            return (
                todays: buckets.today,
                tomorrows: buckets.tomorrowStrict,
                laters: targetCategory == .allUpcoming ? buckets.laterUpcoming : [],
                noDueDates: targetCategory == .allUpcoming ? buckets.noDueDate : []
            )
        } else {
            let calendar = Calendar.autoupdatingCurrent
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
                    if targetCategory == .allUpcoming { noDueDates.append(item) }
                    continue
                }
                if dueDate < startOfTomorrow {
                    todays.append(item)
                } else if dueDate < startOfDayAfter {
                    tomorrows.append(item)
                } else if targetCategory == .allUpcoming {
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

            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatingPhase = 5
            }

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
            Task {
                _ = await reminderService.checkAuthorizationStatus()
                reminderService.updateReminderContent()
            }
        }
        .onChange(of: selectedFilter) {
            selectedSubjectFilter = "Tất cả"
            autoSelectFirstItem()
        }
        .onChange(of: selectedSubjectFilter) {
            let list = currentFilteredList
            if let current = selectedCoursework, list.contains(where: { $0.id == current.id }) {
                selectedCourseworkIds = selectedCourseworkIds.filter { id in list.contains(where: { $0.id == id }) }
                if selectedCourseworkIds.isEmpty {
                    selectedCourseworkIds = [current.id]
                }
            } else if let first = list.first {
                selectedCoursework = first
                selectedCourseworkIds = [first.id]
            } else {
                selectedCoursework = nil
                selectedCourseworkIds.removeAll()
            }
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
            if scenePhase == .background || scenePhase == .active {
                reminderService.updateReminderContent()
            }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettingsModal"))) { _ in
            clientIdInput = authService.configuredClientId
            clientSecretInput = authService.configuredClientSecret
            showSettingsModal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerSync"))) { _ in
            Task {
                triggerHapticFeedback()
                await apiService.syncAll()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    refreshData()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateNewPersonalNote"))) { _ in
            selectedFilter = .notes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: NSNotification.Name("OpenCreateNoteSheet"), object: nil)
            }
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
                    .offset(y: floatingPhase > 0 ? -4 : 4)
                    .scaleEffect(floatingPhase > 0 ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floatingPhase)
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
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
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

    #if os(iOS)
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact || isLandscapePhone
    }
    #endif

    @ViewBuilder
    private var mainAppContainer: some View {
        #if os(iOS)
        if isCompactLayout {
            compactAppView
        } else {
            splitViewContainer
        }
        #else
        splitViewContainer
        #endif
    }

    #if os(iOS)
    private struct CompactTabDefinition: Identifiable {
        let category: AppFilterCategory
        let shortTitle: String
        let icon: String
        let badgeCount: Int?

        var id: String { category.rawValue }
    }

    private var compactTabs: [CompactTabDefinition] {
        var items: [CompactTabDefinition] = [
            CompactTabDefinition(
                category: .tomorrow,
                shortTitle: "Báo bài",
                icon: "calendar.badge.clock",
                badgeCount: buckets.tomorrowPendingCount > 0 ? buckets.tomorrowPendingCount : nil
            ),
            CompactTabDefinition(
                category: .todayAndTomorrow,
                shortTitle: "Hôm nay",
                icon: "clock",
                badgeCount: buckets.todayAndTomorrowPendingCount > 0 ? buckets.todayAndTomorrowPendingCount : nil
            ),
            CompactTabDefinition(
                category: .allUpcoming,
                shortTitle: "Sắp tới",
                icon: "tray",
                badgeCount: buckets.allUpcomingPendingCount > 0 ? buckets.allUpcomingPendingCount : nil
            ),
        ]
        if buckets.past.count > 0 {
            items.append(
                CompactTabDefinition(
                    category: .past,
                    shortTitle: "Quá hạn",
                    icon: "clock.badge.exclamationmark",
                    badgeCount: buckets.past.count
                )
            )
        }
        items.append(
            CompactTabDefinition(
                category: .completed,
                shortTitle: "Đã xong",
                icon: "checkmark.seal",
                badgeCount: buckets.completed.count > 0 ? buckets.completed.count : nil
            )
        )
        let pendingNotesCount = personalNotes.filter { $0.courseworkId == nil && !$0.isCompleted }.count
        items.append(
            CompactTabDefinition(
                category: .notes,
                shortTitle: "Ghi chú",
                icon: "square.and.pencil",
                badgeCount: pendingNotesCount > 0 ? pendingNotesCount : nil
            )
        )
        if buckets.past.count == 0 {
            items.append(
                CompactTabDefinition(
                    category: .widgetPreview,
                    shortTitle: "Widget",
                    icon: "macwindow",
                    badgeCount: nil
                )
            )
        }
        return items
    }

    @ViewBuilder
    private var compactAppView: some View {
        TabView(selection: $selectedFilter) {
            ForEach(compactTabs) { tab in
                NavigationStack {
                    detailMasterView(isCompact: true, tabCategory: tab.category)
                }
                .tabItem {
                    Label(tab.shortTitle, systemImage: tab.icon)
                }
                .badge(tab.badgeCount ?? 0)
                .tag(tab.category)
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.platformWindowBackground, for: .tabBar)
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
                let pendingNotesCount = personalNotes.filter { $0.courseworkId == nil && !$0.isCompleted }.count
                sidebarCategoryRow(for: .notes, count: pendingNotesCount > 0 ? pendingNotesCount : nil)
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
            #if os(macOS)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(categoryIconColor(category).opacity(0.12))
                    .frame(width: 24, height: 24)

                Image(systemName: category.icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(categoryIconColor(category))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
            }

            Text(category.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(Color.platformTextPrimary)
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
                            .fill(categoryBadgeBg(category))
                            .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
                    )
                    .foregroundStyle(categoryBadgeFg(category))
                    .scaleEffect(isSelected ? 1.06 : 1.0)
            }
            #else
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
            #endif
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
        case .notes: return Color(red: 0.95, green: 0.55, blue: 0.10)
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
    private func detailMasterView(isCompact: Bool, tabCategory: AppFilterCategory? = nil) -> some View {
        let activeCategory = tabCategory ?? selectedFilter
        VStack(spacing: 0) {
            headerBarView(category: activeCategory)

            if updateService.updateAvailable {
                updateBannerView
            }

            Divider()

            if activeCategory == .widgetPreview {
                ScrollView {
                    widgetPreviewSection
                        #if os(iOS)
                        .padding(horizontalSizeClass == .compact ? 12 : 24)
                        #else
                        .padding(24)
                        #endif
                }
            } else if activeCategory == .notes {
                PersonalNotesView(
                    notes: personalNotes,
                    courses: courses,
                    searchText: searchText,
                    onToggleCompletion: { id in
                        ClassroomStorage.shared.togglePersonalNoteCompletion(id: id)
                        personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                        recomputeBuckets()
                    },
                    onSaveNote: { note in
                        var current = personalNotes
                        if let index = current.firstIndex(where: { $0.id == note.id }) {
                            current[index] = note
                        } else {
                            current.append(note)
                        }
                        ClassroomStorage.shared.savePersonalNotes(current)
                        personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                        recomputeBuckets()
                        showToast(title: "Đã lưu ghi chú", icon: "checkmark.circle.fill", tint: .green)
                    },
                    onDeleteNote: { id in
                        ClassroomStorage.shared.deletePersonalNote(id: id)
                        personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                        recomputeBuckets()
                        showToast(title: "Đã xoá ghi chú", icon: "trash.fill", tint: .orange)
                    }
                )
            } else {
                #if os(iOS)
                if isCompact {
                    assignmentListPane(isWide: false, category: activeCategory)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                } else {
                    GeometryReader { geometry in
                        let isWide = geometry.size.width >= 560
                        if isWide {
                            let listWidth = min(350, max(260, geometry.size.width * 0.38))
                            HStack(spacing: 0) {
                                assignmentListPane(isWide: true, category: activeCategory)
                                    .frame(width: listWidth)

                                Divider()

                                homeworkReaderPane
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            assignmentListPane(isWide: false, category: activeCategory)
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
                }
                #else
                GeometryReader { geometry in
                    let isWide = geometry.size.width >= 440
                    if isWide {
                        let listWidth = min(360, max(260, geometry.size.width * 0.38))
                        HStack(spacing: 0) {
                            assignmentListPane(isWide: true, category: activeCategory)
                                .frame(width: listWidth)

                            Divider()

                            homeworkReaderPane
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        assignmentListPane(isWide: false, category: activeCategory)
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
        .navigationTitle(activeCategory.rawValue)
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
                    if !isSearchFocused {
                        Button("") { selectNextItem() }
                            .keyboardShortcut(.downArrow, modifiers: [])
                        Button("") { selectPreviousItem() }
                            .keyboardShortcut(.upArrow, modifiers: [])
                    }
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
                    Button("") {
                        if let item = selectedCoursework {
                            triggerHapticFeedback()
                            openURL(item.destinationURL)
                        }
                    }
                    .keyboardShortcut("o", modifiers: [.command])
                    #endif
                }
                .opacity(0)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            }
        }
        .toolbar {
            #if os(iOS)
            if !isCompact && (horizontalSizeClass == .compact || isLandscapePhone) {
                ToolbarItem(placement: .topBarLeading) {
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
                    #if os(iOS)
                    if apiService.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    #else
                    if apiService.isSyncing {
                        HStack(spacing: 5) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Đang đồng bộ...")
                        }
                    } else {
                        Label("Đồng bộ", systemImage: "arrow.triangle.2.circlepath")
                    }
                    #endif
                }
                .onChange(of: apiService.isSyncing) {
                    if !apiService.isSyncing {
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
    private func headerBarView(category: AppFilterCategory? = nil) -> some View {
        let activeCategory = category ?? selectedFilter
        #if os(iOS)
        if horizontalSizeClass == .compact || isLandscapePhone {
            mobileCompactHeaderBar(category: activeCategory)
        } else {
            regularHeaderBar(category: activeCategory)
        }
        #else
        regularHeaderBar(category: activeCategory)
        #endif
    }

    #if os(iOS)
    private func mobileCompactHeaderBar(category: AppFilterCategory) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.platformTextTertiary)
                Text(formattedCurrentDate())
                    .font(.system(size: 14, weight: .semibold))
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
                        .font(.system(size: 12.5, weight: .semibold))
                    Text("Lớp (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                        .font(.system(size: 13.5, weight: .medium))
                }
                .foregroundStyle(Color.platformTextSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.platformControlBackground)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if category == .widgetPreview {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11.5, weight: .semibold))
                    Text("Xem trước")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.purple.opacity(0.08))
                .clipShape(Capsule())
            } else if category == .notes {
                let pendingCount = personalNotes.filter { $0.courseworkId == nil && !$0.isCompleted }.count
                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryIconColor(category))
                        .frame(width: 6, height: 6)
                    Text("\(pendingCount) việc cần làm")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(categoryIconColor(category))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(categoryIconColor(category).opacity(0.09))
                .clipShape(Capsule())
            } else {
                let pendingCount = currentFilteredList(for: category).filter { !$0.isCompleted }.count
                if pendingCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(categoryIconColor(category))
                            .frame(width: 6, height: 6)
                        Text("\(pendingCount) cần nộp")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(categoryIconColor(category))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(categoryIconColor(category).opacity(0.09))
                    .clipShape(Capsule())
                } else if !currentFilteredList(for: category).isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10.5, weight: .bold))
                        Text("Đã nộp hết")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
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
        .padding(.vertical, isLandscapePhone ? 4 : 8)
        .background(Color.platformWindowBackground)
    }
    #endif

    private func regularHeaderBar(category: AppFilterCategory) -> some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(categoryIconColor(category).opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: category.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(categoryIconColor(category))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
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

            if category == .widgetPreview {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11.5, weight: .semibold))
                    Text("Cấu hình & Xem trước Widget")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.purple)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(Color.purple.opacity(0.08))
                .clipShape(Capsule())
            } else if category == .notes {
                let pendingCount = personalNotes.filter { $0.courseworkId == nil && !$0.isCompleted }.count
                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryIconColor(category))
                        .frame(width: 6, height: 6)
                    Text("\(pendingCount) việc cần làm")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(categoryIconColor(category))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(categoryIconColor(category).opacity(0.09))
                .clipShape(Capsule())
            } else {
                let pendingCount = currentFilteredList(for: category).filter { !$0.isCompleted }.count
                if pendingCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(categoryIconColor(category))
                            .frame(width: 6, height: 6)
                        Text("\(pendingCount) bài cần nộp")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(categoryIconColor(category))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(categoryIconColor(category).opacity(0.09))
                    .clipShape(Capsule())
                } else if !currentFilteredList(for: category).isEmpty {
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
        return "Tìm bài tập... (⌘F)"
        #else
        return "Tìm bài tập..."
        #endif
    }

    private func assignmentListPane(isWide: Bool = true, category: AppFilterCategory? = nil) -> some View {
        let activeCategory = category ?? selectedFilter
        let list = currentFilteredList(for: activeCategory)
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(isSearchFocused ? .blue : Color.platformTextTertiary)

                TextField(searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
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
            #if os(iOS)
            .padding(.vertical, isLandscapePhone ? 5.5 : 8.5)
            #else
            .padding(.vertical, 8.5)
            #endif
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
            #if os(iOS)
            .padding(.top, isLandscapePhone ? 4 : 10)
            .padding(.bottom, isLandscapePhone ? 3 : 6)
            #else
            .padding(.top, 10)
            .padding(.bottom, 6)
            #endif
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
            } else if activeCategory == .completed && !list.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                    Text("\(list.count) bài đã hoàn thành")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Color.platformTextSecondary)
                        .contentTransition(.numericText())
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            if activeCategory == .allUpcoming && availableSubjectPills.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableSubjectPills, id: \.self) { pill in
                            let isSelected = (selectedSubjectFilter == pill)
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                                    if isSelected && pill != "Tất cả" {
                                        selectedSubjectFilter = "Tất cả"
                                    } else {
                                        selectedSubjectFilter = pill
                                    }
                                }
                            } label: {
                                Text(pill)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? Color.white : Color.platformTextSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4.5)
                                    .background(
                                        isSelected
                                            ? Color.blue
                                            : Color.platformControlBackground
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.clear : Color.platformCardBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 2)
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
                    filter: activeCategory,
                    isSearching: !searchText.trimmingCharacters(in: .whitespaces).isEmpty || (activeCategory == .allUpcoming && selectedSubjectFilter != "Tất cả"),
                    searchText: searchText.isEmpty ? (selectedSubjectFilter != "Tất cả" ? "Môn \(selectedSubjectFilter)" : "") : searchText,
                    onClearSearch: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            searchText = ""
                            selectedSubjectFilter = "Tất cả"
                        }
                    },
                    onSwitchToUpcoming: {
                        selectedFilter = .allUpcoming
                    }
                )
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        let hasNoteForItem: (Coursework) -> Bool = { item in
                            personalNotes.contains { $0.courseworkId == item.id && !$0.content.isEmpty }
                        }

                        if activeCategory == .tomorrow {
                            if !list.isEmpty && searchText.isEmpty {
                                tomorrowProgressHeroCard
                            }

                            ForEach(list) { item in
                                AssignmentListRow(
                                    item: item,
                                    isSelected: selectedCourseworkIds.contains(item.id),
                                    hasNote: hasNoteForItem(item),
                                    onSelect: { cmdPressed in
                                        handleItemTap(item, commandPressed: cmdPressed, isWide: isWide)
                                    },
                                    onToggleCompletion: {
                                        toggleCompletion(for: item)
                                    }
                                )
                                .equatable()
                            }
                        } else if activeCategory == .todayAndTomorrow || activeCategory == .allUpcoming {
                            let sections = categorizedSections(for: list, category: activeCategory)

                            if !sections.todays.isEmpty {
                                SectionHeaderPill(title: "HÔM NAY", count: sections.todays.count, icon: "clock.fill", color: Color(red: 0.95, green: 0.55, blue: 0.10))
                                ForEach(sections.todays) { item in
                                    AssignmentListRow(
                                        item: item,
                                        isSelected: selectedCourseworkIds.contains(item.id),
                                        hasNote: hasNoteForItem(item),
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
                                        hasNote: hasNoteForItem(item),
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
                                        hasNote: hasNoteForItem(item),
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
                                        hasNote: hasNoteForItem(item),
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
                                    hasNote: hasNoteForItem(item),
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
                    .animation(.spring(response: 0.32, dampingFraction: 0.8), value: list)
                    #if os(iOS)
                    .padding(.bottom, isLandscapePhone ? 24 : 8)
                    #endif
                }
                .onChange(of: selectedCoursework?.id) { targetId in
                    if let targetId {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            scrollProxy.scrollTo(targetId, anchor: .center)
                        }
                    }
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
        }
        .background(Color.platformWindowBackground)
    }

    private var tomorrowProgressHeroCard: some View {
        let totalCount = buckets.tomorrow.count
        let completedCount = buckets.tomorrow.filter(\.isCompleted).count
        let incompleteCount = totalCount - completedCount
        let isAllDone = totalCount > 0 && incompleteCount == 0
        let progressFraction = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0

        let emotion: EmberEmotion = {
            if isAllDone { return .celebrating }
            if incompleteCount >= 3 { return .stressed }
            return .normal
        }()

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                ChunkyEmberCharacterView(emotion: emotion, size: 52)
                    .offset(y: floatingPhase > 0 ? -4 : 4)
                    .scaleEffect(floatingPhase > 0 ? 1.03 : 0.97)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floatingPhase)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isAllDone ? "Xuất sắc! Đã xong hết" : "Báo bài ngày mai")
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text(isAllDone ? "Đã hoàn thành toàn bộ bài tập ngày mai. 🎉" : "Còn \(incompleteCount) bài tập cần nộp.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }

            VStack(spacing: 5) {
                HStack {
                    Text(isAllDone ? "Hoàn thành 100%! 🎉" : "Tiến độ: \(completedCount)/\(totalCount) bài tập")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))

                    Spacer()

                    Text("\(Int(progressFraction * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.90))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(6, geo.size.width * CGFloat(progressFraction)), height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: progressFraction)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(13)
        .background(ChunkyTheme.skyGradient)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 3)
        .padding(.bottom, 4)
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
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.blue)
                                    Text("HƯỚNG DẪN BÀI TẬP")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.platformTextSecondary)
                                }

                                Spacer()

                                if let desc = item.description, !desc.isEmpty {
                                    Button {
                                        copyToClipboard(desc, title: item.title)
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
                                    Text("Không có mô tả chi tiết.")
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
                                    TextEditor(text: $courseworkNoteEditingText)
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
                                            saveCourseworkNote(for: item, content: courseworkNoteEditingText)
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

                        Spacer(minLength: 16)

                        HStack {
                            #if os(macOS)
                            Spacer()
                            #endif
                            Button {
                                triggerHapticFeedback()
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
            copyToClipboard(desc, title: item.title)
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
                GuideStepRow(step: "3", text: "Tìm kiếm 'Báo bài Ngày mai' trong danh sách tiện ích bên dưới.")
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
                    if authService.isAuthenticated {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(Color.blue)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(authService.currentUserName ?? "Tài khoản Google")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text(authService.currentUserEmail ?? "Không rõ")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)

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
                                        icon: "checkmark.circle.fill",
                                        tint: .green
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(apiService.isSyncing ? "Đang đồng bộ..." : "Đồng bộ bài tập ngay")
                            }
                        }
                        .disabled(apiService.isSyncing)

                        Button("Đăng xuất", role: .destructive) {
                            showLogoutConfirmation = true
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Chưa kết nối tài khoản Google Classroom")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("Đăng nhập để đồng bộ bài tập và hạn chót từ các lớp học của bạn.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)

                        Button {
                            showSettingsModal = false
                            startGoogleLogin()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                Text("Đăng nhập bằng Google")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Label("Tài khoản", systemImage: "person.crop.circle")
                }

                Section {
                    Toggle("Nhắc nhở mỗi tối", isOn: Binding(
                        get: { reminderService.isEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await reminderService.requestAuthorization()
                                    if granted {
                                        reminderService.isEnabled = true
                                    } else {
                                        reminderService.isEnabled = false
                                        showToast(
                                            title: "Chưa cấp quyền thông báo",
                                            subtitle: "Vui lòng bật quyền Thông báo trong Cài đặt hệ thống để nhận báo bài",
                                            icon: "bell.slash",
                                            tint: .orange
                                        )
                                    }
                                }
                            } else {
                                reminderService.isEnabled = false
                            }
                        }
                    ))

                    if reminderService.isEnabled {
                        DatePicker(
                            "Giờ báo bài",
                            selection: Binding(
                                get: {
                                    var c = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
                                    c.hour = reminderService.reminderHour
                                    c.minute = reminderService.reminderMinute
                                    return Calendar.autoupdatingCurrent.date(from: c) ?? Date()
                                },
                                set: { newDate in
                                    let comps = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: newDate)
                                    reminderService.setReminderTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Xem trước thông báo:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(reminderService.previewNotificationText())
                                .font(.system(size: 12.5))
                                .foregroundStyle(.primary)
                                .padding(9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.platformSubtleFill)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label("Báo bài buổi tối", systemImage: "moon.stars.fill")
                } footer: {
                    Text("Ứng dụng tự động thông báo tóm tắt các bài tập cần nộp vào ngày mai để bạn chuẩn bị tập vở và soạn cặp.")
                }

                Section {
                    HStack {
                        Text("Phiên bản hiện tại:")
                        Spacer()
                        Text("v\(updateService.currentVersion)")
                            .foregroundStyle(.secondary)
                    }

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

                Section {
                    DisclosureGroup(
                        isExpanded: $isAdvancedSettingsExpanded,
                        content: {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Dữ liệu thử nghiệm")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Dùng để kiểm tra giao diện và thẻ bài tập khi không có dữ liệu thật.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Button("Nạp lại dữ liệu mẫu (Hôm nay & mai)") {
                                        ClassroomStorage.shared.saveCourses(ClassroomStorage.mockCourses)
                                        ClassroomStorage.shared.saveCoursework(ClassroomStorage.mockCoursework)
                                        refreshData()
                                        autoSelectFirstItem()
                                        showToast(
                                            title: "Đã nạp lại dữ liệu mẫu!",
                                            subtitle: "Bao gồm các bài tập mẫu cho hôm nay & ngày mai",
                                            icon: "sparkles",
                                            tint: .purple
                                        )
                                    }
                                    .font(.system(size: 12))
                                }

                                Divider()

                                #if os(macOS)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("GitHub Token (Tùy chọn)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Chỉ cần thiết nếu kiểm tra bản cập nhật từ kho lưu trữ GitHub riêng tư.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    TextField("GitHub Personal Access Token", text: Binding(
                                        get: { updateService.githubToken },
                                        set: { updateService.githubToken = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                }

                                Divider()
                                #endif

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Cấu hình Google Client ID riêng")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Ứng dụng đã có sẵn Google Client ID mặc định. Người dùng thông thường không cần chỉnh sửa phần này.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Client ID:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        TextField("Google Client ID", text: $clientIdInput)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Client Secret (Tùy chọn):")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        SecureField("Google Client Secret", text: $clientSecretInput)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))
                                    }

                                    HStack {
                                        Button("Khôi phục mặc định") {
                                            clientIdInput = GoogleOAuthService.bundledClientId
                                            clientSecretInput = GoogleOAuthService.bundledClientSecret
                                            authService.configuredClientId = GoogleOAuthService.bundledClientId
                                            authService.configuredClientSecret = GoogleOAuthService.bundledClientSecret
                                            showToast(
                                                title: "Đã khôi phục Client ID mặc định",
                                                icon: "arrow.counterclockwise",
                                                tint: .blue
                                            )
                                        }
                                        .font(.system(size: 12))

                                        Spacer()

                                        Button("Lưu Client ID riêng") {
                                            authService.configuredClientId = clientIdInput
                                            authService.configuredClientSecret = clientSecretInput
                                            showToast(
                                                title: "Đã lưu cấu hình Client ID",
                                                icon: "checkmark.circle.fill",
                                                tint: .green
                                            )
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 6)
                        },
                        label: {
                            Label("Tùy chọn nâng cao", systemImage: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .medium))
                        }
                    )
                } header: {
                    Text("Dành cho nhà phát triển")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Cài đặt")
            .confirmationDialog(
                "Đăng xuất khỏi Google?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Đăng xuất và xóa cache", role: .destructive) {
                    authService.signOut()
                    isDemoMode = false
                    refreshData()
                    autoSelectFirstItem()
                    showSettingsModal = false
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn đăng xuất tài khoản Google? Dữ liệu bài tập offline trên thiết bị sẽ được xóa.")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        showSettingsModal = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.cancelAction)
                    .fontWeight(.semibold)
                }
            }
            #if os(macOS)
            .frame(minWidth: 460, minHeight: 400)
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
        if isSearchFocused {
            isSearchFocused = false
            if !searchText.isEmpty {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    searchText = ""
                }
            }
        } else if !searchText.isEmpty {
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
        self.personalNotes = ClassroomStorage.shared.loadPersonalNotes()
        recomputeBuckets()

        if let current = selectedCoursework, currentFilteredList.contains(where: { $0.id == current.id }) {
            if let updated = allCoursework.first(where: { $0.id == current.id }) {
                self.selectedCoursework = updated
            }
        } else {
            autoSelectFirstItem()
        }
    }

    private func saveCourseworkNote(for item: Coursework, content: String) {
        ClassroomStorage.shared.saveNoteForCoursework(
            courseworkId: item.id,
            courseId: item.courseId,
            courseName: item.courseName,
            title: item.title,
            content: content
        )
        self.personalNotes = ClassroomStorage.shared.loadPersonalNotes()
        recomputeBuckets()
        showToast(title: "Đã cập nhật ghi chú bài tập", icon: "checkmark.circle.fill", tint: .green)
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

        for id in ids {
            if let index = allCoursework.firstIndex(where: { $0.id == id }) {
                allCoursework[index].status = .turnedIn
                allCoursework[index].isManuallyCompleted = true
            }
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            recomputeBuckets()
            selectedCourseworkIds.removeAll()
            if let current = selectedCoursework, ids.contains(current.id) {
                selectedCoursework = allCoursework.first(where: { $0.id == current.id })
            }
        }

        ClassroomStorage.shared.saveCoursework(allCoursework)
        reminderService.updateReminderContent()

        showToast(
            title: "Đã hoàn thành \(ids.count) bài tập!",
            icon: "checkmark.circle.fill",
            tint: .green
        )
    }

    private func toggleCompletion(for item: Coursework) {
        triggerHapticFeedback()

        if let index = allCoursework.firstIndex(where: { $0.id == item.id }) {
            let wasCompleted = allCoursework[index].isCompleted
            let newManuallyCompleted = !wasCompleted
            allCoursework[index].isManuallyCompleted = newManuallyCompleted
            allCoursework[index].status = newManuallyCompleted ? .turnedIn : .pending

            let currentItem = allCoursework[index]
            let itemCourse = currentItem.courseName
            let itemTitle = currentItem.title

            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                recomputeBuckets()
                if selectedCoursework?.id == item.id {
                    selectedCoursework = currentItem
                }
            }

            ClassroomStorage.shared.saveCoursework(allCoursework)
            reminderService.updateReminderContent()

            if newManuallyCompleted {
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
        } else if item.id.hasPrefix("note_") {
            let noteId = String(item.id.dropFirst(5))
            ClassroomStorage.shared.togglePersonalNoteCompletion(id: noteId)
            self.personalNotes = ClassroomStorage.shared.loadPersonalNotes()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                recomputeBuckets()
                if let updated = buckets.tomorrow.first(where: { $0.id == item.id }) {
                    if selectedCoursework?.id == item.id {
                        selectedCoursework = updated
                    }
                }
            }
            showToast(
                title: item.isCompleted ? "Đã chuyển về chưa xong" : "Đã hoàn thành ghi chú!",
                subtitle: item.title,
                icon: "checkmark.circle.fill",
                tint: .green
            )
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
                #if canImport(AuthenticationServices)
                if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                    isSigningIn = false
                    return
                }
                #endif
                let nsError = error as NSError
                if (nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1) || nsError.code == 499 {
                    isSigningIn = false
                    return
                }
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

private struct SectionHeaderPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Spacer()

            Text("\(count) bài")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 7.5)
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

#if os(iOS)
private struct RowSelectedShadowModifier: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected {
            content.shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        } else {
            content
        }
    }
}
#endif

private struct AssignmentListRow: View, Equatable {
    let item: Coursework
    let isSelected: Bool
    var hasNote: Bool = false
    let onSelect: (Bool) -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false
    @State private var isRowPressed: Bool = false
    @Environment(\.openURL) private var openURL

    static func == (lhs: AssignmentListRow, rhs: AssignmentListRow) -> Bool {
        lhs.item == rhs.item && lhs.isSelected == rhs.isSelected && lhs.hasNote == rhs.hasNote
    }

    var isTurnedIn: Bool {
        item.isCompleted
    }

    var body: some View {
        let themeColor = SubjectArtHelper.themeColor(for: item.courseName, title: item.title)

        HStack(alignment: .center, spacing: 9) {
            Capsule()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(width: 3.5, height: 34)
                .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isSelected)

            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                    checkmarkBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                        checkmarkBounce = false
                    }
                }
                onToggleCompletion()
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 32)
                        .equatable()

                    if isTurnedIn {
                        if #available(macOS 14.0, iOS 17.0, *) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                                .background(Circle().fill(Color.white).padding(1))
                                .offset(x: 3, y: 3)
                                .scaleEffect(checkmarkBounce ? 1.32 : 1.0)
                                .symbolEffect(.bounce, value: isTurnedIn)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
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
                            .frame(width: 13, height: 13)
                            .offset(x: 2, y: 2)
                            .scaleEffect(checkmarkBounce ? 0.9 : 1.0)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .scaleEffect(checkmarkBounce ? 1.15 : 1.0)
            }
            #if os(macOS)
            .frame(width: 34, height: 34)
            #else
            .frame(width: 44, height: 44)
            #endif
            .contentShape(Rectangle())
            .buttonStyle(SpringPressButtonStyle(scale: 0.92, pressedOpacity: 0.88))
            .help(isTurnedIn ? "Đã nộp bài (Space hoặc bấm để hoàn tác)" : "Chưa nộp bài (Space hoặc bấm để đánh dấu hoàn thành)")

            VStack(alignment: .leading, spacing: 3.5) {
                #if os(macOS)
                Text(item.title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                    .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                    .opacity(isTurnedIn ? 0.72 : 1.0)
                    .lineLimit(2)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isTurnedIn)

                HStack(spacing: 5) {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 6, height: 6)
                    Text(item.courseName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(themeColor)
                        .lineLimit(1)
                    if hasNote {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    }
                }
                .opacity(isTurnedIn ? 0.75 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isTurnedIn)
                #else
                Text(item.title)
                    .font(.system(size: 16.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                    .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                    .opacity(isTurnedIn ? 0.72 : 1.0)
                    .lineLimit(2)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isTurnedIn)

                HStack(spacing: 5) {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 6, height: 6)
                    Text(item.courseName)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(themeColor)
                        .lineLimit(1)
                    if hasNote {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    }
                }
                .opacity(isTurnedIn ? 0.75 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isTurnedIn)
                #endif
            }

            Spacer(minLength: 4)

            DueBadgeView(item: item, compact: true)
                .equatable()
        }
        .padding(.horizontal, 11)
        #if os(iOS)
        .padding(.vertical, 10)
        .frame(minHeight: 62)
        #else
        .padding(.vertical, 6)
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
        .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        #else
        .modifier(RowSelectedShadowModifier(isSelected: isSelected))
        #endif
        .scaleEffect(isRowPressed ? 0.98 : (isHovered ? 1.006 : 1.0))
        .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isRowPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.16, dampingFraction: 0.65)) {
                isRowPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                    isRowPressed = false
                }
            }
            #if os(macOS)
            let isCmd = NSEvent.modifierFlags.contains(.command)
            #else
            let isCmd = false
            #endif
            onSelect(isCmd)
        }
        .onChange(of: isTurnedIn) {
            if isTurnedIn {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                    checkmarkBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                        checkmarkBounce = false
                    }
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

private struct AssignmentListEmptyView: View {
    let filter: ContentView.AppFilterCategory
    let isSearching: Bool
    let searchText: String
    let onClearSearch: () -> Void
    var onSwitchToUpcoming: (() -> Void)? = nil

    @State private var hasAppeared: Bool = false
    @State private var isEmberFloating: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if !isSearching && (filter == .tomorrow || filter == .todayAndTomorrow) {
                ChunkyEmberCharacterView(emotion: .sleeping, size: 76)
                    .offset(y: isEmberFloating ? -5 : 4)
                    .scaleEffect(isEmberFloating ? 1.02 : 0.98)
                    .padding(.bottom, 2)
            } else if !isSearching && filter == .past {
                ChunkyEmberCharacterView(emotion: .celebrating, size: 76)
                    .offset(y: isEmberFloating ? -5 : 4)
                    .scaleEffect(isEmberFloating ? 1.02 : 0.98)
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

                    if #available(macOS 14.0, iOS 17.0, *) {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(emptyTint)
                            .symbolEffect(.bounce, value: hasAppeared)
                    } else {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(emptyTint)
                    }
                }
                .offset(y: isEmberFloating ? -3 : 3)
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
                .buttonStyle(SpringPressButtonStyle(scale: 0.96))
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
                .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                .controlSize(.regular)
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.94)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                hasAppeared = true
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isEmberFloating = true
            }
        }
    }

    private var emptyIcon: String {
        if isSearching { return "magnifyingglass" }
        switch filter {
        case .tomorrow: return "calendar.badge.checkmark"
        case .todayAndTomorrow: return "sun.max"
        case .allUpcoming: return "tray"
        case .past: return "checkmark.seal.fill"
        case .completed: return "doc.text.magnifyingglass"
        case .notes: return "square.and.pencil"
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
        case .notes: return .orange
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
        case .notes: return "Chưa có ghi chú nào"
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
        case .notes:
            return "Các ghi chú cá nhân của bạn sẽ hiển thị tại đây."
        case .widgetPreview:
            return "Kéo thả widget ra màn hình chính để theo dõi nhanh bài tập."
        }
    }
}

private struct HomeworkReaderEmptyStateView: View {
    @State private var hasAppeared: Bool = false

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
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .offset(y: hasAppeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                hasAppeared = true
            }
        }
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
