import SwiftUI
import WidgetKit
import Combine
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
    public var floats: Bool
    @State private var isFloating: Bool = false

    public init(size: CGFloat = 84, floats: Bool = false) {
        self.size = size
        self.floats = floats
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
        .offset(y: floats && isFloating ? -4 : 0)
        .scaleEffect(floats && isFloating ? 1.02 : 1.0)
        .animation(floats ? .easeInOut(duration: 2.6).repeatForever(autoreverses: true) : nil, value: isFloating)
        .onAppear {
            if floats {
                isFloating = true
            }
        }
    }

    private var fallbackIcon: some View {
        ZStack {
            ChunkyTheme.skyGradient
            ChunkyEmberCharacterView(emotion: .normal, size: size * 0.72)
        }
        .frame(width: size, height: size)
    }
}

public struct FloatingEmberView: View {
    public let emotion: EmberEmotion
    public var size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating: Bool = false

    public init(emotion: EmberEmotion, size: CGFloat = 52) {
        self.emotion = emotion
        self.size = size
    }

    public var body: some View {
        ChunkyEmberCharacterView(emotion: emotion, size: size)
            .offset(y: reduceMotion ? 0 : (isFloating ? -4 : 4))
            .scaleEffect(reduceMotion ? 1.0 : (isFloating ? 1.025 : 0.975))
            .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: isFloating)
            .onAppear {
                if !reduceMotion {
                    isFloating = true
                }
            }
    }
}

private final class AssignmentListCache {
    final class CategorizedSectionsResult {
        let todays: [Coursework]
        let tomorrows: [Coursework]
        let laters: [Coursework]
        let noDueDates: [Coursework]

        init(todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
            self.todays = todays
            self.tomorrows = tomorrows
            self.laters = laters
            self.noDueDates = noDueDates
        }
    }

    private var lastCategory: ContentView.AppFilterCategory?
    private var lastSearchText: String = ""
    private var lastSubjectFilter: String = ""
    private var lastCourseworkCount: Int = -1
    private var lastCourseworkVersion: Int = -1
    private var cachedFilteredList: [Coursework] = []

    private var lastSectionsCategory: ContentView.AppFilterCategory?
    private var lastSectionsListCount: Int = -1
    private var lastSectionsSearchText: String = ""
    private var lastSectionsSubjectFilter: String = ""
    private var lastSectionsCourseworkVersion: Int = -1
    private var cachedSections: CategorizedSectionsResult = CategorizedSectionsResult(todays: [], tomorrows: [], laters: [], noDueDates: [])

    func filteredList(
        category: ContentView.AppFilterCategory,
        searchText: String,
        subjectFilter: String,
        courseworkCount: Int,
        courseworkVersion: Int,
        compute: () -> [Coursework]
    ) -> [Coursework] {
        if lastCategory == category &&
            lastSearchText == searchText &&
            lastSubjectFilter == subjectFilter &&
            lastCourseworkCount == courseworkCount &&
            lastCourseworkVersion == courseworkVersion {
            return cachedFilteredList
        }
        let result = compute()
        lastCategory = category
        lastSearchText = searchText
        lastSubjectFilter = subjectFilter
        lastCourseworkCount = courseworkCount
        lastCourseworkVersion = courseworkVersion
        cachedFilteredList = result
        return result
    }

    func categorizedSections(
        list: [Coursework],
        category: ContentView.AppFilterCategory,
        searchText: String,
        subjectFilter: String,
        courseworkVersion: Int,
        compute: () -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework])
    ) -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
        if lastSectionsCategory == category &&
            lastSectionsListCount == list.count &&
            lastSectionsSearchText == searchText &&
            lastSectionsSubjectFilter == subjectFilter &&
            lastSectionsCourseworkVersion == courseworkVersion {
            return (cachedSections.todays, cachedSections.tomorrows, cachedSections.laters, cachedSections.noDueDates)
        }
        let result = compute()
        lastSectionsCategory = category
        lastSectionsListCount = list.count
        lastSectionsSearchText = searchText
        lastSectionsSubjectFilter = subjectFilter
        lastSectionsCourseworkVersion = courseworkVersion
        cachedSections = CategorizedSectionsResult(
            todays: result.todays,
            tomorrows: result.tomorrows,
            laters: result.laters,
            noDueDates: result.noDueDates
        )
        return result
    }
}

public struct ContentView: View {
    @StateObject private var authService = GoogleOAuthService.shared
    @StateObject private var apiService = ClassroomAPIService.shared
    @StateObject private var updateService = AppUpdateService.shared
    @StateObject private var reminderService = EveningReminderService.shared

    @State private var courseworkVersion: Int = 0
    @State private var listCache = AssignmentListCache()

    @State private var courses: [Course] = []
    @State private var allCoursework: [Coursework] = []
    @State private var personalNotes: [PersonalNote] = []
    @State private var courseworkNoteEditingText: String = ""
    @State private var courseworkNoteToEditCourseworkId: String? = nil
    @State private var buckets = CourseworkBuckets()
    @State private var availableSubjectPills: [String] = ["Tất cả"]
    @State private var completedDisplayLimit: Int = 30
    @State private var noteCourseworkIds: Set<String> = []
    @State private var pendingNotesCount: Int = 0
    @State private var totalIndependentNotesCount: Int = 0
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
    @State private var noteToEditFromReader: PersonalNote? = nil
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
            self.tomorrowStrict = tomorrowStrict
            self.today = today
            self.laterUpcoming = laterUpcoming
            self.past = past
            self.noDueDate = noDueDate
            self.completed = completed
            self.todayAndTomorrow = today + tomorrowStrict
            self.allUpcoming = today + tomorrowStrict + laterUpcoming + noDueDate

            let tomorrowPending = tomorrow.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let tomorrowStrictPending = tomorrowStrict.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let todayPending = today.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let laterPending = laterUpcoming.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }
            let noDuePending = noDueDate.reduce(0) { $0 + ($1.isCompleted ? 0 : 1) }

            self.tomorrowPendingCount = tomorrowPending
            self.todayAndTomorrowPendingCount = todayPending + tomorrowStrictPending
            self.allUpcomingPendingCount = todayPending + tomorrowStrictPending + laterPending + noDuePending
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

        let calendar = ClassroomDateFormatters.gregorianCalendar
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

        let sameStatusDueDateAscending: (Coursework, Coursework) -> Bool = {
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

        tomorrowsStrict.sort(by: sameStatusDueDateAscending)
        todays.sort(by: sameStatusDueDateAscending)
        laters.sort(by: sameStatusDueDateAscending)
        pasts.sort(by: sameStatusDueDateAscending)
        comp.sort(by: dueDateDescending)
        noDates.sort(by: sameStatusDueDateAscending)

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

        self.courseworkVersion &+= 1

        updateAvailableSubjectPills()
    }

    private func updateAvailableSubjectPills() {
        let pool = (selectedFilter == .completed) ? self.buckets.completed : self.buckets.allUpcoming
        let subjects = Set(pool.map(\.badgeCode)).sorted()
        self.availableSubjectPills = ["Tất cả"] + subjects

        if selectedSubjectFilter != "Tất cả" && !self.availableSubjectPills.contains(selectedSubjectFilter) {
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

    private func categoryPendingCount(_ category: AppFilterCategory) -> Int {
        if !searchText.isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            let cleanQuery = query.normalizedForVietnameseSearch()
            let tokens = cleanQuery.searchQueryTokens()
            guard !tokens.isEmpty else { return 0 }
            let base = baseFilteredList(for: category)
            return base.reduce(0) { count, item in
                if !item.isCompleted && tokens.allSatisfy({ item.searchIndex.contains($0) }) {
                    return count + 1
                }
                return count
            }
        }
        switch category {
        case .tomorrow:
            return buckets.tomorrowPendingCount
        case .todayAndTomorrow:
            return buckets.todayAndTomorrowPendingCount
        case .allUpcoming:
            return buckets.allUpcomingPendingCount
        case .past:
            return buckets.pastPendingCount
        case .completed:
            return buckets.completedCount
        case .notes:
            return pendingNotesCount
        case .widgetPreview:
            return 0
        }
    }

    private func categoryHasItems(_ category: AppFilterCategory) -> Bool {
        if !searchText.isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            let cleanQuery = query.normalizedForVietnameseSearch()
            let tokens = cleanQuery.searchQueryTokens()
            guard !tokens.isEmpty else { return false }
            return baseFilteredList(for: category).contains { item in
                tokens.allSatisfy { item.searchIndex.contains($0) }
            }
        }
        switch category {
        case .tomorrow: return !buckets.tomorrow.isEmpty
        case .todayAndTomorrow: return !buckets.todayAndTomorrow.isEmpty
        case .allUpcoming: return !buckets.allUpcoming.isEmpty
        case .past: return !buckets.past.isEmpty
        case .completed: return !buckets.completed.isEmpty
        case .notes, .widgetPreview: return false
        }
    }

    private func currentFilteredList(for category: AppFilterCategory) -> [Coursework] {
        listCache.filteredList(
            category: category,
            searchText: searchText,
            subjectFilter: selectedSubjectFilter,
            courseworkCount: allCoursework.count,
            courseworkVersion: courseworkVersion
        ) {
            computeFilteredList(for: category)
        }
    }

    private func computeFilteredList(for category: AppFilterCategory) -> [Coursework] {
        var baseList = baseFilteredList(for: category)
        if (category == .allUpcoming || category == .completed) && selectedSubjectFilter != "Tất cả" {
            baseList = baseList.filter { item in
                item.badgeCode == selectedSubjectFilter
            }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return baseList }

        let cleanQuery = query.normalizedForVietnameseSearch()
        let tokens = cleanQuery.searchQueryTokens()
        guard !tokens.isEmpty else { return baseList }

        var scored: [(item: Coursework, score: Int)] = []
        scored.reserveCapacity(baseList.count)
        let tokenCount = tokens.count
        for item in baseList {
            let index = item.searchIndex
            var matchesAll = true
            for t in 0..<tokenCount {
                if !index.contains(tokens[t]) {
                    matchesAll = false
                    break
                }
            }
            if matchesAll {
                scored.append((item: item, score: item.searchRelevanceScore(for: tokens, rawNormalizedQuery: cleanQuery)))
            }
        }
        guard !scored.isEmpty else { return [] }
        scored.sort { first, second in
            if first.score != second.score {
                return first.score > second.score
            }
            return first.item < second.item
        }
        var result: [Coursework] = []
        result.reserveCapacity(scored.count)
        for entry in scored {
            result.append(entry.item)
        }
        return result
    }

    private var baseFilteredList: [Coursework] {
        baseFilteredList(for: selectedFilter)
    }

    private var currentFilteredList: [Coursework] {
        currentFilteredList(for: selectedFilter)
    }

    private func categorizedSections(for list: [Coursework], category: AppFilterCategory? = nil) -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
        let targetCategory = category ?? selectedFilter
        return listCache.categorizedSections(
            list: list,
            category: targetCategory,
            searchText: searchText,
            subjectFilter: selectedSubjectFilter,
            courseworkVersion: courseworkVersion
        ) {
            computeCategorizedSections(for: list, category: targetCategory)
        }
    }

    private func computeCategorizedSections(for list: [Coursework], category: AppFilterCategory) -> (todays: [Coursework], tomorrows: [Coursework], laters: [Coursework], noDueDates: [Coursework]) {
        let targetCategory = category
        let isDefaultFilter = searchText.trimmingCharacters(in: .whitespaces).isEmpty && (targetCategory != .allUpcoming || selectedSubjectFilter == "Tất cả")
        if isDefaultFilter {
            return (
                todays: buckets.today,
                tomorrows: buckets.tomorrowStrict,
                laters: targetCategory == .allUpcoming ? buckets.laterUpcoming : [],
                noDueDates: targetCategory == .allUpcoming ? buckets.noDueDate : []
            )
        } else {
            let calendar = ClassroomDateFormatters.gregorianCalendar
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

            if authService.isAuthenticated {
                ClassroomStorage.shared.saveUserLoggedIn(true)
                ClassroomStorage.shared.notifyWidgetReload()
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
            updateAvailableSubjectPills()
            completedDisplayLimit = 30
            autoSelectFirstItem()
        }
        .onChange(of: selectedSubjectFilter) {
            completedDisplayLimit = 30
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
            completedDisplayLimit = 30
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
                ClassroomStorage.shared.saveUserLoggedIn(true)
                ClassroomStorage.shared.notifyWidgetReload()
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
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                refreshData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                refreshData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenLoginOrSettings"))) { _ in
            if !authService.isAuthenticated {
                clientIdInput = authService.configuredClientId
                clientSecretInput = authService.configuredClientSecret
                showSettingsModal = true
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
                ClassroomStorage.shared.saveUserLoggedIn(true)
                ClassroomStorage.shared.notifyWidgetReload()
                Task {
                    await apiService.syncAll()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        refreshData()
                    }
                }
            } else {
                ClassroomStorage.shared.saveUserLoggedIn(false)
                ClassroomStorage.shared.notifyWidgetReload()
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

                AppLogoView(size: 88, floats: true)
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
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
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
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                welcomeAppeared = true
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
        Group {
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
        .sheet(item: $noteToEditFromReader) { note in
            CreateOrEditNoteSheet(
                existingNote: note,
                courses: courses,
                onSave: { updated in
                    savePersonalNoteItem(updated)
                    noteToEditFromReader = nil
                },
                onCancel: {
                    noteToEditFromReader = nil
                }
            )
        }
    }

    #if os(iOS)
    private var compactTabSelectionBinding: Binding<AppFilterCategory> {
        Binding(
            get: {
                if selectedFilter == .todayAndTomorrow || selectedFilter == .past {
                    return .allUpcoming
                }
                return selectedFilter
            },
            set: { newCategory in
                if selectedFilter != newCategory {
                    if !searchText.isEmpty {
                        searchText = ""
                    }
                    selectedFilter = newCategory
                }
            }
        )
    }

    @ViewBuilder
    private var compactAppView: some View {
        let upcomingBadge = buckets.allUpcomingPendingCount + buckets.pastPendingCount
        TabView(selection: compactTabSelectionBinding) {
            NavigationStack {
                detailMasterView(isCompact: true, tabCategory: .tomorrow)
            }
            .tabItem {
                Label("Báo bài", systemImage: "calendar.badge.clock")
            }
            .tag(AppFilterCategory.tomorrow)
            .badge(buckets.tomorrowPendingCount > 0 ? buckets.tomorrowPendingCount : 0)

            NavigationStack {
                detailMasterView(isCompact: true, tabCategory: .allUpcoming)
            }
            .tabItem {
                Label("Sắp tới", systemImage: "tray.fill")
            }
            .tag(AppFilterCategory.allUpcoming)
            .badge(upcomingBadge > 0 ? upcomingBadge : 0)

            NavigationStack {
                detailMasterView(isCompact: true, tabCategory: .completed)
            }
            .tabItem {
                Label("Đã xong", systemImage: "checkmark.seal.fill")
            }
            .tag(AppFilterCategory.completed)

            NavigationStack {
                detailMasterView(isCompact: true, tabCategory: .notes)
            }
            .tabItem {
                Label("Ghi chú", systemImage: "square.and.pencil")
            }
            .tag(AppFilterCategory.notes)
            .badge(pendingNotesCount > 0 ? pendingNotesCount : 0)
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $showCompactCourseFilterSheet) {
            compactCourseFilterSheetView
        }
        .sheet(isPresented: $showMobileDetailSheet) {
            NavigationStack {
                homeworkReaderPane
                    .navigationTitle(selectedCoursework?.id.hasPrefix("note_") == true ? "Chi tiết việc cần làm" : "Chi tiết bài tập")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Xong") { showMobileDetailSheet = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var compactCourseFilterSheetView: some View {
        CompactCourseFilterSheet(
            courses: courses,
            isPresented: $showCompactCourseFilterSheet,
            onToggleCourse: { courseId in
                toggleCourse(courseId: courseId)
            },
            onToggleAllCourses: {
                toggleAllCourses()
            }
        )
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
                    AdaptiveGlassContainer(spacing: 6) {
                        Button(allSelected ? "Bỏ chọn hết" : "Tất cả") {
                            toggleAllCourses()
                        }
                        .buttonStyle(.plain)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(allSelected ? Color.secondary : Color.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
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
        .listStyle(.sidebar)
        .navigationTitle("Classroom")
        #if os(macOS)
        .tint(categoryIconColor(selectedFilter))
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
        #if os(macOS)
        let iconBgColor = isSelected ? Color.white.opacity(0.24) : categoryIconColor(category).opacity(0.12)
        let iconFgColor = isSelected ? Color.white : categoryIconColor(category)
        let textFgColor = isSelected ? Color.white : Color.platformTextPrimary
        let badgeBgColor = isSelected ? Color.white : categoryBadgeBg(category)
        let badgeFgColor = isSelected ? categoryIconColor(category) : categoryBadgeFg(category)
        let badgeShadowColor = isSelected ? Color.black.opacity(0.12) : Color.clear
        #else
        let iconBgColor = categoryIconColor(category).opacity(isSelected ? 0.20 : 0.12)
        let iconFgColor = categoryIconColor(category)
        let textFgColor = isSelected ? categoryIconColor(category) : Color.platformTextPrimary
        let badgeBgColor = isSelected ? categoryIconColor(category).opacity(0.18) : categoryBadgeBg(category)
        let badgeFgColor = categoryIconColor(category)
        let badgeShadowColor = Color.clear
        #endif

        return HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconBgColor)
                    .frame(width: 24, height: 24)

                Image(systemName: category.icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(iconFgColor)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
            }

            Text(category.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(textFgColor)
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
                            .fill(badgeBgColor)
                            .shadow(color: badgeShadowColor, radius: 2, x: 0, y: 1)
                    )
                    .foregroundStyle(badgeFgColor)
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
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            ClassroomStorage.shared.togglePersonalNoteCompletion(id: id)
                            personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                            updatePersonalNotesCache()
                            recomputeBuckets()
                            if selectedCoursework?.id == id || selectedCoursework?.id == "note_\(id)" {
                                if let note = personalNotes.first(where: { $0.id == id }) {
                                    selectedCoursework = Coursework(
                                        id: "note_\(note.id)",
                                        courseId: note.courseId ?? "personal_note",
                                        courseName: note.courseName ?? "Ghi chú",
                                        title: note.title,
                                        description: note.content,
                                        dueDate: note.dueDate,
                                        status: note.isCompleted ? .turnedIn : .pending,
                                        isManuallyCompleted: note.isCompleted
                                    )
                                }
                            }
                        }
                        if let note = personalNotes.first(where: { $0.id == id }) {
                            if note.isCompleted {
                                showToast(title: "Đã hoàn thành việc cần làm!", subtitle: note.title, icon: "checkmark.circle.fill", tint: .green)
                            } else {
                                showToast(title: "Đã chuyển về chưa xong", subtitle: note.title, icon: "arrow.uturn.backward.circle.fill", tint: .orange)
                            }
                        }
                    },
                    onToggleChecklistItem: { noteId, itemId in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            ClassroomStorage.shared.toggleChecklistItemCompletion(noteId: noteId, itemId: itemId)
                            personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                            updatePersonalNotesCache()
                            recomputeBuckets()
                            if selectedCoursework?.id == noteId || selectedCoursework?.id == "note_\(noteId)" {
                                if let note = personalNotes.first(where: { $0.id == noteId }) {
                                    selectedCoursework = Coursework(
                                        id: "note_\(note.id)",
                                        courseId: note.courseId ?? "personal_note",
                                        courseName: note.courseName ?? "Ghi chú",
                                        title: note.title,
                                        description: note.content,
                                        dueDate: note.dueDate,
                                        status: note.isCompleted ? .turnedIn : .pending,
                                        isManuallyCompleted: note.isCompleted
                                    )
                                }
                            }
                        }
                    },
                    onSaveNote: { note in
                        savePersonalNoteItem(note)
                    },
                    onDeleteNote: { id in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            ClassroomStorage.shared.deletePersonalNote(id: id)
                            personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                            updatePersonalNotesCache()
                            recomputeBuckets()
                            if selectedCoursework?.id == id || selectedCoursework?.id == "note_\(id)" {
                                selectedCoursework = nil
                            }
                            selectedCourseworkIds.remove(id)
                            selectedCourseworkIds.remove("note_\(id)")
                        }
                        showToast(title: "Đã xoá việc cần làm", icon: "trash.fill", tint: .orange)
                    }
                )
            } else {
                #if os(iOS)
                if isCompact {
                    assignmentListPane(isWide: false, category: activeCategory)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                .navigationTitle(selectedCoursework?.id.hasPrefix("note_") == true ? "Chi tiết việc cần làm" : "Chi tiết bài tập")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Xong") { showMobileDetailSheet = false }
                                    }
                                }
                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
                #else
                GeometryReader { geometry in
                    let isWide = geometry.size.width >= 520
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
                            .navigationTitle(selectedCoursework?.id.hasPrefix("note_") == true ? "Chi tiết việc cần làm" : "Chi tiết bài tập")
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
        .navigationTitle(activeCategory.rawValue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .overlay(alignment: .bottom) {
            if let toast = activeToast {
                FloatingToastHUD(toast: toast, onDismiss: { dismissToast() })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.92))
                    ))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: activeToast)
        .background {
            if !showSettingsModal && activeCategory != .notes && activeCategory != .widgetPreview && courseworkNoteToEditCourseworkId == nil {
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
                        if !isSearchFocused {
                            if selectedCourseworkIds.count > 1 {
                                batchToggleCompletion(for: selectedCourseworkIds)
                            } else if let item = selectedCoursework {
                                toggleCompletion(for: item)
                            }
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    Button("") {
                        if !isSearchFocused {
                            if selectedCourseworkIds.count > 1 {
                                batchToggleCompletion(for: selectedCourseworkIds)
                            } else if let item = selectedCoursework {
                                toggleCompletion(for: item)
                            }
                        }
                    }
                    .keyboardShortcut("d", modifiers: [.command])
                    Button("") {
                        if let item = selectedCoursework {
                            if item.id.hasPrefix("note_") {
                                let noteId = String(item.id.dropFirst(5))
                                if let note = personalNotes.first(where: { $0.id == noteId }) {
                                    triggerHapticFeedback()
                                    noteToEditFromReader = note
                                }
                            } else {
                                triggerHapticFeedback()
                                openURL(item.destinationURL)
                            }
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
                Text(formattedCompactCurrentDate())
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.platformTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(0)

            Spacer(minLength: 4)

            AdaptiveGlassContainer(spacing: 6) {
                HStack(spacing: 6) {
                    Button {
                        showCompactCourseFilterSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 12.5, weight: .semibold))
                            Text("Lớp (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                                .font(.system(size: 13.5, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.platformTextSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .appleLiquidGlassSurface(style: .interactive, in: Capsule()) {
                            Capsule().fill(Color.platformControlBackground)
                        }
                    }
                    .buttonStyle(.plain)
                    .fixedSize()

                    if category == .widgetPreview {
                        HStack(spacing: 4) {
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 11.5, weight: .semibold))
                            Text("Xem trước")
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .appleLiquidGlassSurface(style: .tint(Color.purple.opacity(0.12)), in: Capsule()) {
                            Capsule().fill(Color.purple.opacity(0.08))
                        }
                        .fixedSize()
                    } else if category == .notes {
                        if pendingNotesCount == 0 && totalIndependentNotesCount > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("Đã xong hết")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .appleLiquidGlassSurface(style: .tint(Color.green.opacity(0.14)), in: Capsule()) {
                                Capsule().fill(Color.green.opacity(0.12))
                            }
                            .fixedSize()
                        } else {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6, height: 6)
                                Text("\(pendingNotesCount) việc cần làm")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .appleLiquidGlassSurface(style: .tint(categoryIconColor(category).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(categoryIconColor(category).opacity(0.09))
                            }
                            .fixedSize()
                        }
                    } else {
                        let pendingCount = categoryPendingCount(category)
                        if pendingCount > 0 {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6, height: 6)
                                Text("\(pendingCount) cần nộp")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .appleLiquidGlassSurface(style: .tint(categoryIconColor(category).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(categoryIconColor(category).opacity(0.09))
                            }
                            .fixedSize()
                        } else if categoryHasItems(category) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10.5, weight: .bold))
                                Text("Đã nộp hết")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .appleLiquidGlassSurface(style: .tint(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.10))
                            }
                            .fixedSize()
                        }
                    }

                    if apiService.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(5)
                    } else if authService.isAuthenticated {
                        Button {
                            Task {
                                await apiService.syncAll()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    refreshData()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Color.platformTextSecondary)
                                .padding(5.5)
                                .appleLiquidGlassSurface(style: .interactive, in: Circle()) {
                                    Circle().fill(Color.platformControlBackground)
                                }
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }

                    Button {
                        clientIdInput = authService.configuredClientId
                        clientSecretInput = authService.configuredClientSecret
                        showSettingsModal = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.platformTextSecondary)
                            .padding(5.5)
                            .appleLiquidGlassSurface(style: .interactive, in: Circle()) {
                                Circle().fill(Color.platformControlBackground)
                            }
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
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

            AdaptiveGlassContainer(spacing: 8) {
                HStack(spacing: 8) {
                    if category == .widgetPreview {
                        HStack(spacing: 6) {
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 11.5, weight: .semibold))
                            Text("Cấu hình & Xem trước Widget")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(.purple)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .appleLiquidGlassSurface(style: .tint(Color.purple.opacity(0.12)), in: Capsule()) {
                            Capsule().fill(Color.purple.opacity(0.08))
                        }
                        .fixedSize()
                    } else if category == .notes {
                        if pendingNotesCount == 0 && totalIndependentNotesCount > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("Đã xong hết")
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .appleLiquidGlassSurface(style: .tint(Color.green.opacity(0.14)), in: Capsule()) {
                                Capsule().fill(Color.green.opacity(0.12))
                            }
                            .fixedSize()
                        } else {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6, height: 6)
                                Text("\(pendingNotesCount) việc cần làm")
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .appleLiquidGlassSurface(style: .tint(categoryIconColor(category).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(categoryIconColor(category).opacity(0.09))
                            }
                            .fixedSize()
                        }
                    } else {
                        let pendingCount = categoryPendingCount(category)
                        if pendingCount > 0 {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6, height: 6)
                                Text("\(pendingCount) bài cần nộp")
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .appleLiquidGlassSurface(style: .tint(categoryIconColor(category).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(categoryIconColor(category).opacity(0.09))
                            }
                            .fixedSize()
                        } else if categoryHasItems(category) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9.5, weight: .bold))
                                Text("Đã nộp tất cả")
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .appleLiquidGlassSurface(style: .tint(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.12)), in: Capsule()) {
                                Capsule().fill(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.10))
                            }
                            .fixedSize()
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
                        .appleLiquidGlassSurface(style: .regular, in: Capsule()) {
                            Capsule().fill(Color.platformControlBackground)
                        }
                        .overlay(
                            Capsule()
                                .stroke(Color.platformCardBorder, lineWidth: 1)
                        )
                        .fixedSize()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.platformWindowBackground)
    }

    private var updateBannerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.orange)
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

    @ViewBuilder
    private func assignmentItemRow(item: Coursework, isWide: Bool) -> some View {
        AssignmentListRow(
            item: item,
            isSelected: selectedCourseworkIds.contains(item.id),
            hasNote: noteCourseworkIds.contains(item.id),
            onSelect: { cmdPressed in
                handleItemTap(item, commandPressed: cmdPressed, isWide: isWide)
            },
            onToggleCompletion: {
                toggleCompletion(for: item)
            }
        )
        .equatable()
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
            .appleLiquidGlassSurface(
                style: isSearchFocused ? .interactiveTint(Color.blue.opacity(0.12)) : .interactive,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            ) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSearchFocused ? Color.blue.opacity(0.55) : Color.platformCardBorder.opacity(0.8), lineWidth: 1)
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

            if (activeCategory == .allUpcoming || activeCategory == .completed) && availableSubjectPills.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    AdaptiveGlassContainer(spacing: 6) {
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
                                        completedDisplayLimit = 30
                                    }
                                } label: {
                                    Text(pill)
                                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.white : Color.platformTextSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4.5)
                                        .appleLiquidGlassSurface(
                                            style: isSelected ? .interactiveTint(Color.blue) : .interactive,
                                            in: Capsule()
                                        ) {
                                            Capsule()
                                                .fill(isSelected ? Color.blue : Color.platformControlBackground)
                                        }
                                        .overlay(
                                            Capsule()
                                                .stroke(isSelected ? Color.clear : Color.platformCardBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 2)
            }

            if selectedCourseworkIds.count > 1 {
                let allSelectedDone = selectedCourseworkIds.allSatisfy { id in
                    if let cw = allCoursework.first(where: { $0.id == id }) {
                        return cw.isCompleted
                    } else if id.hasPrefix("note_") {
                        let noteId = String(id.dropFirst(5))
                        return personalNotes.first(where: { $0.id == noteId })?.isCompleted == true
                    }
                    return false
                }

                HStack(spacing: 8) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.blue)

                    Text("Đã chọn \(selectedCourseworkIds.count) bài tập")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.platformTextPrimary)

                    Spacer()

                    AdaptiveGlassContainer(spacing: 6) {
                        Button {
                            batchToggleCompletion(for: selectedCourseworkIds)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: allSelectedDone ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                Text(allSelectedDone ? "Chưa nộp" : "Đã nộp")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .appleLiquidGlassSurface(
                                style: .interactiveTint(allSelectedDone ? Color.orange : Color(red: 0.12, green: 0.62, blue: 0.35)),
                                in: Capsule()
                            ) {
                                Capsule().fill(allSelectedDone ? Color.orange : Color(red: 0.12, green: 0.62, blue: 0.35))
                            }
                        }
                        .buttonStyle(.plain)

                        Button("Bỏ chọn") {
                            handleDeselectAll()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.platformTextSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .appleLiquidGlassSurface(
                            style: .interactive,
                            in: Capsule()
                        ) {
                            Capsule().fill(Color.platformControlBackground)
                        }
                        .overlay(
                            Capsule().stroke(Color.platformCardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .appleLiquidGlassSurface(
                    style: .regular,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                ) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.platformControlBackground)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.platformCardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()

            let hasOverdueToDisplay = activeCategory == .allUpcoming && !buckets.past.isEmpty && searchText.isEmpty && selectedSubjectFilter == "Tất cả"
            let isCategoryFiltering = (activeCategory == .allUpcoming || activeCategory == .completed) && selectedSubjectFilter != "Tất cả"
            if list.isEmpty && !hasOverdueToDisplay {
                AssignmentListEmptyView(
                    filter: activeCategory,
                    isSearching: !searchText.trimmingCharacters(in: .whitespaces).isEmpty || isCategoryFiltering,
                    searchText: searchText.isEmpty ? (selectedSubjectFilter != "Tất cả" ? "Môn \(selectedSubjectFilter)" : "") : searchText,
                    onClearSearch: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            searchText = ""
                            selectedSubjectFilter = "Tất cả"
                            completedDisplayLimit = 30
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
                        if activeCategory == .tomorrow {
                            if !list.isEmpty && searchText.isEmpty {
                                tomorrowHeroBanner
                                tomorrowProgressHeroCard
                            }

                            let pendingItems = list.filter { !$0.isCompleted }
                            let completedItems = list.filter { $0.isCompleted }

                            if !pendingItems.isEmpty {
                                let groupedPending = Dictionary(grouping: pendingItems, by: { $0.courseName.isEmpty ? "Chung" : $0.courseName })
                                let sortedCourses = groupedPending.keys.sorted()

                                ForEach(sortedCourses, id: \.self) { courseName in
                                    let courseItems = groupedPending[courseName] ?? []
                                    SubjectGroupHeaderRow(courseName: courseName, count: courseItems.count)

                                    ForEach(courseItems) { item in
                                        assignmentItemRow(item: item, isWide: isWide)
                                    }
                                }
                            }

                            if !completedItems.isEmpty {
                                CompletedSectionHeaderRow(count: completedItems.count)

                                ForEach(completedItems) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }
                        } else if activeCategory == .todayAndTomorrow || activeCategory == .allUpcoming {
                            let sections = categorizedSections(for: list, category: activeCategory)

                            if hasOverdueToDisplay {
                                SectionHeaderPill(title: "QUÁ HẠN", count: buckets.past.count, icon: "clock.badge.exclamationmark.fill", color: Color(red: 0.86, green: 0.24, blue: 0.26))
                                ForEach(buckets.past) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }

                            if !sections.todays.isEmpty {
                                SectionHeaderPill(title: "HÔM NAY", count: sections.todays.count, icon: "clock.fill", color: Color(red: 0.95, green: 0.55, blue: 0.10))
                                ForEach(sections.todays) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }

                            if !sections.tomorrows.isEmpty {
                                SectionHeaderPill(title: "NGÀY MAI", count: sections.tomorrows.count, icon: "calendar", color: Color(red: 0.12, green: 0.55, blue: 0.95))
                                ForEach(sections.tomorrows) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }

                            if !sections.laters.isEmpty {
                                SectionHeaderPill(title: "SẮP TỚI", count: sections.laters.count, icon: "tray", color: .secondary)
                                ForEach(sections.laters) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }

                            if !sections.noDueDates.isEmpty {
                                SectionHeaderPill(title: "KHÔNG CÓ HẠN", count: sections.noDueDates.count, icon: "questionmark.circle", color: .secondary)
                                ForEach(sections.noDueDates) { item in
                                    assignmentItemRow(item: item, isWide: isWide)
                                }
                            }
                        } else if activeCategory == .completed {
                            let displayedItems = Array(list.prefix(completedDisplayLimit))
                            ForEach(displayedItems) { item in
                                assignmentItemRow(item: item, isWide: isWide)
                            }

                            if list.count > completedDisplayLimit {
                                VStack(spacing: 8) {
                                    Text("Đang hiển thị \(displayedItems.count)/\(list.count) bài đã hoàn thành")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.platformTextSecondary)

                                    HStack(spacing: 10) {
                                        Button {
                                            completedDisplayLimit += 30
                                        } label: {
                                            Label("Xem thêm 30 bài cũ hơn", systemImage: "chevron.down.circle")
                                                .font(.system(size: 12.5, weight: .semibold))
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)

                                        if list.count > completedDisplayLimit + 30 {
                                            Button("Xem tất cả") {
                                                completedDisplayLimit = list.count
                                            }
                                            .buttonStyle(.plain)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color.blue)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        } else {
                            ForEach(list) { item in
                                assignmentItemRow(item: item, isWide: isWide)
                            }
                        }
                    }
                    .padding(12)
                    .animation(list.count < 50 ? .spring(response: 0.32, dampingFraction: 0.8) : nil, value: list.count)
                    #if os(iOS)
                    .padding(.bottom, isLandscapePhone ? 24 : 8)
                    #endif
                }
                .onChange(of: selectedCoursework?.id) { _, targetId in
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
                FloatingEmberView(emotion: emotion, size: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isAllDone ? "Xuất sắc! Đã xong hết" : "Báo bài ngày mai")
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text(isAllDone ? "Đã hoàn thành toàn bộ bài tập ngày mai." : "Còn \(incompleteCount) bài tập cần nộp.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                AdaptiveGlassContainer(spacing: 4) {
                    ShareLink(item: formattedBaoBaiShareText) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .bold))
                            Text("Chia sẻ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .appleLiquidGlassSurface(style: .interactiveTint(Color.white.opacity(0.3)), in: Capsule()) {
                            Capsule().fill(Color.white.opacity(0.22))
                        }
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 5) {
                HStack {
                    Text(isAllDone ? "Hoàn thành 100%!" : "Tiến độ: \(completedCount)/\(totalCount) bài tập")
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
        .appleLiquidGlassSurface(
            style: .tint(Color.blue.opacity(0.35)),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        ) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(ChunkyTheme.skyGradient)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 3)
        .padding(.bottom, 4)
    }

    private var tomorrowHeroBanner: some View {
        #if os(macOS)
        let img = NSImage(named: "HeroBaoBai")
        #else
        let img = UIImage(named: "HeroBaoBai")
        #endif
        return Group {
            if img != nil {
                ZStack(alignment: .bottom) {
                    Image("HeroBaoBai")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 128)
                        .clipped()

                    LinearGradient(
                        colors: [Color.clear, Color.platformWindowBackground.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.platformCardBorder.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.bottom, 4)
            }
        }
    }

    private var formattedBaoBaiShareText: String {
        let items = buckets.tomorrow
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = ClassroomDateFormatters.gregorianCalendar
        formatter.dateFormat = "EEEE, 'ngày' dd/MM"
        let dateStr = formatter.string(from: ClassroomDateFormatters.gregorianCalendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())

        if items.isEmpty {
            return """
            BÁO BÀI NGÀY MAI (\(dateStr))

            Tuyệt vời! Ngày mai bạn không có bài tập nào cần làm.
            Nghỉ ngơi thật tốt nhé!

            ---
            Classroom Tracker
            """
        }

        var lines = [
            "BÁO BÀI NGÀY MAI (\(dateStr))\n"
        ]
        for item in items {
            let statusTag = item.isCompleted ? "[Đã xong]" : "[Chưa xong]"
            let courseTag = !item.courseName.isEmpty ? "[\(item.courseName)]" : "[Chung]"
            let dueStr = item.dueDate != nil ? "Hạn: \(item.timeOnlyString)" : "Không hạn"
            lines.append("\(statusTag) \(courseTag) \(item.title) (\(dueStr))")
        }
        lines.append("\n---\nClassroom Tracker")
        return lines.joined(separator: "\n")
    }

    private var homeworkReaderPane: some View {
        HomeworkReaderPane(
            selectedCourseworkIds: selectedCourseworkIds,
            currentFilteredList: currentFilteredList,
            selectedCoursework: selectedCoursework,
            personalNotes: personalNotes,
            copyFeedbackMessage: copyFeedbackMessage,
            courseworkNoteToEditCourseworkId: $courseworkNoteToEditCourseworkId,
            courseworkNoteEditingText: $courseworkNoteEditingText,
            onMarkAllDone: { ids in
                batchToggleCompletion(for: ids)
            },
            onDeselectAll: {
                handleDeselectAll()
            },
            onToggleCompletion: { item in
                toggleCompletion(for: item)
            },
            onCopyToClipboard: { desc, title in
                copyToClipboard(desc, title: title)
            },
            onSaveCourseworkNote: { item, note in
                saveCourseworkNote(for: item, content: note)
            },
            onTriggerHaptic: {
                triggerHapticFeedback()
            },
            onToggleChecklistItem: { noteId, itemId in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    ClassroomStorage.shared.toggleChecklistItemCompletion(noteId: noteId, itemId: itemId)
                    personalNotes = ClassroomStorage.shared.loadPersonalNotes()
                    updatePersonalNotesCache()
                    recomputeBuckets()
                    if selectedCoursework?.id == "note_\(noteId)" {
                        if let note = personalNotes.first(where: { $0.id == noteId }) {
                            selectedCoursework = Coursework(
                                id: "note_\(note.id)",
                                courseId: note.courseId ?? "personal_note",
                                courseName: note.courseName ?? "Ghi chú",
                                title: note.title,
                                description: note.content,
                                dueDate: note.dueDate,
                                status: note.isCompleted ? .turnedIn : .pending,
                                isManuallyCompleted: note.isCompleted
                            )
                        }
                    }
                }
            },
            onEditNote: { noteId in
                if let note = personalNotes.first(where: { $0.id == noteId }) {
                    noteToEditFromReader = note
                }
            },
            courses: courses,
            onSavePersonalNote: { updated in
                savePersonalNoteItem(updated)
            }
        )
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
                    AdaptiveGlassContainer(spacing: 10) {
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
                    }
                } else {
                    AdaptiveGlassContainer(spacing: 12) {
                        regularPreviewControls
                    }
                }
                #else
                AdaptiveGlassContainer(spacing: 12) {
                    regularPreviewControls
                }
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
            .appleLiquidGlassSurface(
                style: .regular,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            ) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.platformControlBackground)
            }
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
                .toggleStyle(.switch)
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
        .appleLiquidGlassSurface(
            style: .regular,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        ) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.platformControlBackground)
        }
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
                    .toggleStyle(.switch)

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

                Section {
                    HStack {
                        Label("Hệ điều hành", systemImage: "apple.logo")
                        Spacer()
                        Text(AppleOSDetector.currentOSDescription)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Giao diện Liquid Glass", systemImage: "sparkles")
                        Spacer()
                        Text(AppleOSDetector.supportsLiquidGlass ? "Hoạt động" : "Tương thích")
                            .foregroundStyle(AppleOSDetector.supportsLiquidGlass ? Color.green : Color.secondary)
                    }
                } header: {
                    Text("Thiết bị & Hệ thống")
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
            #elseif os(iOS)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
        if courseworkNoteToEditCourseworkId != nil {
            courseworkNoteToEditCourseworkId = nil
            courseworkNoteEditingText = ""
            return
        }
        if isSearchFocused {
            isSearchFocused = false
            if !searchText.isEmpty {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    searchText = ""
                }
            }
        } else if showMobileDetailSheet {
            showMobileDetailSheet = false
        } else if !searchText.isEmpty {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                searchText = ""
            }
        } else if selectedSubjectFilter != "Tất cả" {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedSubjectFilter = "Tất cả"
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
            if selectedFilter == .completed && nextIdx >= completedDisplayLimit {
                completedDisplayLimit = min(list.count, completedDisplayLimit + 30)
            }
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

    private func updatePersonalNotesCache() {
        self.noteCourseworkIds = Set(personalNotes.lazy.filter { !$0.content.isEmpty }.compactMap(\.courseworkId))
        var pending = 0
        var total = 0
        for note in personalNotes where note.courseworkId == nil {
            total += 1
            if !note.isCompleted {
                pending += 1
            }
        }
        self.pendingNotesCount = pending
        self.totalIndependentNotesCount = total
    }

    private func refreshData() {
        self.courses = ClassroomStorage.shared.loadCourses()
        self.allCoursework = ClassroomStorage.shared.loadCoursework()
        self.personalNotes = ClassroomStorage.shared.loadPersonalNotes()
        updatePersonalNotesCache()
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
        updatePersonalNotesCache()
        recomputeBuckets()
        showToast(title: "Đã cập nhật ghi chú bài tập", icon: "checkmark.circle.fill", tint: .green)
    }

    private func savePersonalNoteItem(_ note: PersonalNote, showFeedbackToast: Bool = true) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            var current = personalNotes
            if let index = current.firstIndex(where: { $0.id == note.id }) {
                current[index] = note
            } else {
                current.append(note)
            }
            ClassroomStorage.shared.savePersonalNotes(current)
            personalNotes = ClassroomStorage.shared.loadPersonalNotes()
            updatePersonalNotesCache()
            recomputeBuckets()
            if selectedCoursework?.id == note.id || selectedCoursework?.id == "note_\(note.id)" {
                selectedCoursework = Coursework(
                    id: "note_\(note.id)",
                    courseId: note.courseId ?? "personal_note",
                    courseName: note.courseName ?? "Ghi chú",
                    title: note.title,
                    description: note.content,
                    dueDate: note.dueDate,
                    status: note.isCompleted ? .turnedIn : .pending,
                    isManuallyCompleted: note.isCompleted
                )
            }
        }
        if showFeedbackToast {
            showToast(title: "Đã lưu việc cần làm", icon: "checkmark.circle.fill", tint: .green)
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

        let allCurrentlyCompleted = ids.allSatisfy { id in
            if let cw = allCoursework.first(where: { $0.id == id }) {
                return cw.isCompleted
            } else if id.hasPrefix("note_") {
                let noteId = String(id.dropFirst(5))
                return personalNotes.first(where: { $0.id == noteId })?.isCompleted == true
            }
            return false
        }
        let targetCompletion = !allCurrentlyCompleted

        var notesChanged = false
        for id in ids {
            if let index = allCoursework.firstIndex(where: { $0.id == id }) {
                allCoursework[index].status = targetCompletion ? .turnedIn : .pending
                allCoursework[index].isManuallyCompleted = targetCompletion
            } else if id.hasPrefix("note_") {
                let noteId = String(id.dropFirst(5))
                ClassroomStorage.shared.setPersonalNoteCompletion(id: noteId, isCompleted: targetCompletion)
                notesChanged = true
            }
        }
        if notesChanged {
            self.personalNotes = ClassroomStorage.shared.loadPersonalNotes()
            updatePersonalNotesCache()
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            recomputeBuckets()
            if let current = selectedCoursework, ids.contains(current.id) {
                if current.id.hasPrefix("note_") {
                    let noteId = String(current.id.dropFirst(5))
                    if let note = personalNotes.first(where: { $0.id == noteId }) {
                        let updated = Coursework(
                            id: "note_\(note.id)",
                            courseId: note.courseId ?? "personal_note",
                            courseName: note.courseName ?? "Ghi chú",
                            title: note.title,
                            description: note.content,
                            dueDate: note.dueDate,
                            status: note.isCompleted ? .turnedIn : .pending,
                            isManuallyCompleted: note.isCompleted
                        )
                        selectedCoursework = updated
                        selectedCourseworkIds = [updated.id]
                    } else {
                        selectedCoursework = nil
                        selectedCourseworkIds.removeAll()
                    }
                } else if let updated = allCoursework.first(where: { $0.id == current.id }) {
                    selectedCoursework = updated
                    selectedCourseworkIds = [updated.id]
                } else {
                    selectedCoursework = nil
                    selectedCourseworkIds.removeAll()
                }
            } else {
                selectedCourseworkIds.removeAll()
                selectedCoursework = nil
            }
        }

        ClassroomStorage.shared.saveCoursework(allCoursework)
        reminderService.updateReminderContent()

        showToast(
            title: targetCompletion ? "Đã hoàn thành \(ids.count) mục!" : "Đã chuyển \(ids.count) mục về chưa nộp",
            icon: targetCompletion ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill",
            tint: targetCompletion ? .green : .orange
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
            updatePersonalNotesCache()
            let updatedNote = personalNotes.first(where: { $0.id == noteId })
            let isNowCompleted = updatedNote?.isCompleted ?? !item.isCompleted
            let updatedCoursework = Coursework(
                id: "note_\(noteId)",
                courseId: updatedNote?.courseId ?? "personal_note",
                courseName: updatedNote?.courseName ?? "Ghi chú",
                title: updatedNote?.title ?? item.title,
                description: updatedNote?.content ?? item.description,
                dueDate: updatedNote?.dueDate ?? item.dueDate,
                status: isNowCompleted ? .turnedIn : .pending,
                isManuallyCompleted: isNowCompleted
            )
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                recomputeBuckets()
                if selectedCoursework?.id == item.id {
                    selectedCoursework = updatedCoursework
                }
            }
            showToast(
                title: isNowCompleted ? "Đã hoàn thành ghi chú!" : "Đã chuyển về chưa xong",
                subtitle: item.title,
                icon: isNowCompleted ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill",
                tint: isNowCompleted ? .green : .orange,
                actionTitle: "Hoàn tác",
                action: { [self] in
                    toggleCompletion(for: updatedCoursework)
                }
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

    private static let compactHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEE, d/M"
        return formatter
    }()

    private func formattedCurrentDate() -> String {
        Self.headerDateFormatter.string(from: Date()).capitalized
    }

    private func formattedCompactCurrentDate() -> String {
        Self.compactHeaderDateFormatter.string(from: Date()).capitalized
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
        .appleLiquidGlassSurface(
            style: .regular,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        ) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toast.tint.opacity(0.35), lineWidth: 1)
        )
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

private struct RowSelectedShadowModifier: ViewModifier {
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

private struct AssignmentListRow: View, Equatable {
    let item: Coursework
    let isSelected: Bool
    var hasNote: Bool = false
    let onSelect: (Bool) -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered: Bool = false
    @State private var checkmarkBounce: Bool = false
    @Environment(\.openURL) private var openURL

    static func == (lhs: AssignmentListRow, rhs: AssignmentListRow) -> Bool {
        lhs.item == rhs.item && lhs.isSelected == rhs.isSelected && lhs.hasNote == rhs.hasNote
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
            }
            .padding(.leading, 11)
            .padding(.trailing, 9)

            HStack(alignment: .center, spacing: 9) {
                VStack(alignment: .leading, spacing: 3.5) {
                    #if os(macOS)
                    Text(item.title)
                        .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                        .opacity(isTurnedIn ? 0.72 : 1.0)
                        .lineLimit(2)

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
                    #else
                    Text(item.title)
                        .font(.system(size: 16.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isTurnedIn ? Color.platformTextSecondary : Color.platformTextPrimary)
                        .strikethrough(isTurnedIn, color: Color.platformTextTertiary)
                        .opacity(isTurnedIn ? 0.72 : 1.0)
                        .lineLimit(2)

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
                    #endif
                }

                Spacer(minLength: 8)

                DueBadgeView(item: item, compact: true)
                    .equatable()
                    .layoutPriority(1)
            }
            .padding(.trailing, 11)
            #if os(iOS)
            .padding(.vertical, 10)
            .frame(minHeight: 62)
            #else
            .padding(.vertical, 6)
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
        .appleLiquidGlassSurface(
            style: isSelected ? .interactiveTint(Color.blue.opacity(0.14)) : .interactive,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        ) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.platformCardSelectedBackground : Color.platformControlBackground)
        }
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

private struct AssignmentListEmptyView: View {
    let filter: ContentView.AppFilterCategory
    let isSearching: Bool
    let searchText: String
    let onClearSearch: () -> Void
    var onSwitchToUpcoming: (() -> Void)? = nil

    @State private var hasAppeared: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if !isSearching && (filter == .tomorrow || filter == .todayAndTomorrow) {
                #if os(macOS)
                let emptyImg = NSImage(named: "EmptyAllCaughtUp")
                #else
                let emptyImg = UIImage(named: "EmptyAllCaughtUp")
                #endif
                if emptyImg != nil {
                    Image("EmptyAllCaughtUp")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 2)
                } else {
                    FloatingEmberView(emotion: .sleeping, size: 76)
                        .padding(.bottom, 2)
                }
            } else if !isSearching && filter == .past {
                FloatingEmberView(emotion: .celebrating, size: 76)
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
                AdaptiveGlassContainer(spacing: 4) {
                    Button("Xóa tìm kiếm") {
                        onClearSearch()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .appleLiquidGlassSurface(
                        style: .interactiveTint(Color.blue.opacity(0.12)),
                        in: Capsule()
                    ) {
                        Capsule().fill(Color.blue.opacity(0.10))
                    }
                    .overlay(
                        Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            } else if (filter == .tomorrow || filter == .todayAndTomorrow), let onSwitchToUpcoming {
                AdaptiveGlassContainer(spacing: 4) {
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
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .appleLiquidGlassSurface(
                        style: .interactiveTint(Color.blue.opacity(0.12)),
                        in: Capsule()
                    ) {
                        Capsule().fill(Color.blue.opacity(0.10))
                    }
                    .overlay(
                        Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.94)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                hasAppeared = true
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

private struct GuideStepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .appleLiquidGlassSurface(
                    style: .interactiveTint(Color.blue.opacity(0.85)),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                ) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.10, green: 0.45, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.platformTextPrimary)
        }
    }
}

private struct SubjectGroupHeaderRow: View {
    let courseName: String
    let count: Int

    var body: some View {
        let themeColor = SubjectArtHelper.themeColor(for: courseName)

        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(themeColor)
                .frame(width: 4, height: 14)

            Text(courseName.uppercased())
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextPrimary)

            Text("\(count) bài")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(themeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(themeColor.opacity(0.12), in: Capsule())

            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

private struct CompletedSectionHeaderRow: View {
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.green)

            Text("ĐÃ HOÀN THÀNH (\(count))")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.platformTextSecondary)

            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }
}
