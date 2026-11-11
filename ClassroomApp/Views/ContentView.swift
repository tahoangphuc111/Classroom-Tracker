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

    final class TomorrowGroupsResult {
        let groupedPending: [(courseName: String, items: [Coursework])]
        let completedItems: [Coursework]

        init(groupedPending: [(courseName: String, items: [Coursework])], completedItems: [Coursework]) {
            self.groupedPending = groupedPending
            self.completedItems = completedItems
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

    private var lastTomorrowListCount: Int = -1
    private var lastTomorrowSearchText: String = ""
    private var lastTomorrowCourseworkVersion: Int = -1
    private var cachedTomorrowGroups: TomorrowGroupsResult = TomorrowGroupsResult(groupedPending: [], completedItems: [])

    private var lastRawQuery: String = ""
    private var cachedCleanQuery: String = ""
    private var cachedTokens: [String] = []

    private var lastCountsSearchText: String = ""
    private var lastCountsVersion: Int = -1
    private var cachedCounts: [ContentView.AppFilterCategory: Int] = [:]

    private var lastHasItemsSearchText: String = ""
    private var lastHasItemsVersion: Int = -1
    private var cachedHasItems: [ContentView.AppFilterCategory: Bool] = [:]

    func searchTokens(for query: String) -> (clean: String, tokens: [String]) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return ("", []) }
        if trimmed == lastRawQuery {
            return (cachedCleanQuery, cachedTokens)
        }
        let clean = trimmed.normalizedForVietnameseSearch()
        let tokens = clean.searchQueryTokens()
        lastRawQuery = trimmed
        cachedCleanQuery = clean
        cachedTokens = tokens
        return (clean, tokens)
    }

    func categoryPendingCount(
        category: ContentView.AppFilterCategory,
        searchText: String,
        courseworkVersion: Int,
        compute: () -> Int
    ) -> Int {
        if lastCountsSearchText == searchText && lastCountsVersion == courseworkVersion {
            if let count = cachedCounts[category] {
                return count
            }
        } else {
            cachedCounts.removeAll(keepingCapacity: true)
            lastCountsSearchText = searchText
            lastCountsVersion = courseworkVersion
        }
        let count = compute()
        cachedCounts[category] = count
        return count
    }

    func categoryHasItems(
        category: ContentView.AppFilterCategory,
        searchText: String,
        courseworkVersion: Int,
        compute: () -> Bool
    ) -> Bool {
        if lastHasItemsSearchText == searchText && lastHasItemsVersion == courseworkVersion {
            if let has = cachedHasItems[category] {
                return has
            }
        } else {
            cachedHasItems.removeAll(keepingCapacity: true)
            lastHasItemsSearchText = searchText
            lastHasItemsVersion = courseworkVersion
        }
        let has = compute()
        cachedHasItems[category] = has
        return has
    }

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

    func tomorrowGroups(
        list: [Coursework],
        searchText: String,
        courseworkVersion: Int,
        compute: () -> TomorrowGroupsResult
    ) -> TomorrowGroupsResult {
        if lastTomorrowListCount == list.count &&
            lastTomorrowSearchText == searchText &&
            lastTomorrowCourseworkVersion == courseworkVersion {
            return cachedTomorrowGroups
        }
        let result = compute()
        lastTomorrowListCount = list.count
        lastTomorrowSearchText = searchText
        lastTomorrowCourseworkVersion = courseworkVersion
        cachedTomorrowGroups = result
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
    @State private var cachedBaoBaiShareText: String = ""
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
    private enum TabTransitionDirection: Sendable {
        case forward
        case backward
    }
    @State private var tabTransitionDirection: TabTransitionDirection = .forward
    #if os(iOS)
    @State private var tabBounceTrigger: [AppFilterCategory: Int] = [:]
    @State private var lastTabHapticTime: TimeInterval = 0
    @State private var lastActiveTabTapTime: TimeInterval = 0
    @State private var dragSwitchedTabInCurrentGesture: Bool = false
    #endif
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

        tomorrowsStrict.sort(by: Coursework.compareByDueDateAscending)
        todays.sort(by: Coursework.compareByDueDateAscending)
        laters.sort(by: Coursework.compareByDueDateAscending)
        pasts.sort(by: Coursework.compareByDueDateAscending)
        comp.sort(by: Coursework.compareByDueDateDescending)
        noDates.sort(by: Coursework.compareByDueDateAscending)

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

        self.cachedBaoBaiShareText = BaoBaiShareHelper.formatBaoBaiText(
            items: self.buckets.tomorrow,
            hasTomorrowTasks: !self.buckets.tomorrowStrict.isEmpty,
            hasTodayTasks: !self.buckets.today.isEmpty
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

    @inline(__always)
    private func itemMatchesTokens(_ item: Coursework, tokens: [String]) -> Bool {
        let index = item.searchIndex
        let tokenCount = tokens.count
        for t in 0..<tokenCount {
            let tok = tokens[t]
            if !index.contains(tok) {
                let altTok = cleanTelexKeystrokes(tok)
                if altTok == tok || !index.contains(altTok) {
                    return false
                }
            }
        }
        return true
    }

    private func categoryPendingCount(_ category: AppFilterCategory) -> Int {
        if !searchText.isEmpty {
            return listCache.categoryPendingCount(
                category: category,
                searchText: searchText,
                courseworkVersion: courseworkVersion
            ) {
                let (_, tokens) = listCache.searchTokens(for: searchText)
                guard !tokens.isEmpty else { return 0 }
                let base = baseFilteredList(for: category)
                var count = 0
                for item in base {
                    if !item.isCompleted && itemMatchesTokens(item, tokens: tokens) {
                        count += 1
                    }
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
            return listCache.categoryHasItems(
                category: category,
                searchText: searchText,
                courseworkVersion: courseworkVersion
            ) {
                let (_, tokens) = listCache.searchTokens(for: searchText)
                guard !tokens.isEmpty else { return false }
                let base = baseFilteredList(for: category)
                for item in base {
                    if itemMatchesTokens(item, tokens: tokens) {
                        return true
                    }
                }
                return false
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
        let (cleanQuery, tokens) = listCache.searchTokens(for: searchText)
        guard !tokens.isEmpty else { return baseList }

        var scored: [(item: Coursework, score: Int)] = []
        scored.reserveCapacity(baseList.count)
        for item in baseList {
            if itemMatchesTokens(item, tokens: tokens) {
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

    private func tomorrowGroups(for list: [Coursework]) -> AssignmentListCache.TomorrowGroupsResult {
        listCache.tomorrowGroups(
            list: list,
            searchText: searchText,
            courseworkVersion: courseworkVersion
        ) {
            let pendingItems = list.filter { !$0.isCompleted }
            let completedItems = list.filter { $0.isCompleted }
            var grouped: [(courseName: String, items: [Coursework])] = []
            if !pendingItems.isEmpty {
                let dict = Dictionary(grouping: pendingItems, by: { $0.courseName.isEmpty ? "Chung" : $0.courseName })
                let sortedKeys = dict.keys.sorted()
                for key in sortedKeys {
                    if let items = dict[key] {
                        grouped.append((courseName: key, items: items))
                    }
                }
            }
            return AssignmentListCache.TomorrowGroupsResult(groupedPending: grouped, completedItems: completedItems)
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
        .overlay(alignment: .top) {
            if let toast = activeToast {
                FloatingToastHUD(toast: toast, onDismiss: { dismissToast() })
                    .padding(.horizontal, 16)
                    #if os(iOS)
                    .padding(.top, 8)
                    #else
                    .padding(.top, 16)
                    #endif
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.92))
                    ))
                    .zIndex(200)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: activeToast)
        .onAppear {
            clientIdInput = authService.configuredClientId
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
        .onChange(of: selectedFilter) { oldValue, newValue in
            let oldIdx = categoryOrder(oldValue)
            let newIdx = categoryOrder(newValue)
            if oldIdx != newIdx {
                tabTransitionDirection = newIdx > oldIdx ? .forward : .backward
            }
            selectedSubjectFilter = "Tất cả"
            updateAvailableSubjectPills()
            completedDisplayLimit = 30
            autoSelectFirstItem()
        }
        .onChange(of: selectedSubjectFilter) {
            reconcileSelectionAfterFilterChange()
        }
        .onChange(of: searchText) {
            reconcileSelectionAfterFilterChange()
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
                Task { @MainActor in
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
            showSettingsModal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerSync"))) { _ in
            Task { @MainActor in
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
        .onDisappear {
            toastDismissTask?.cancel()
            toastDismissTask = nil
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
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Theo dõi bài tập Google Classroom")
                        .font(.system(size: 15.5, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .opacity(welcomeAppeared ? 1 : 0)
                .offset(y: welcomeAppeared ? 0 : 8)

                if let err = errorMessage ?? authService.authErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.system(size: 14, weight: .medium))
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
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Đăng nhập bằng Google")
                                    .font(.system(size: 16, weight: .bold))
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

                            HStack {
                                Button("Mặc định") {
                                    clientIdInput = GoogleOAuthService.bundledClientId
                                    authService.resetToDefaultOAuthCredentials()
                                }
                                .font(.system(size: 11.5))

                                Spacer()

                                Button("Lưu") {
                                    authService.configuredClientId = clientIdInput
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
    private let compactTabCategories: [AppFilterCategory] = [
        .tomorrow,
        .allUpcoming,
        .completed,
        .notes
    ]

    private var activeCompactTab: AppFilterCategory {
        if selectedFilter == .todayAndTomorrow || selectedFilter == .past {
            return .allUpcoming
        }
        return selectedFilter
    }

    private func compactTabIndex(_ category: AppFilterCategory) -> Int {
        compactTabCategories.firstIndex(of: category) ?? 0
    }

    private func triggerTabSelectionHaptic() {
        let now = ProcessInfo.processInfo.systemUptime

        guard now - lastTabHapticTime >= 0.16 else { return }
        lastTabHapticTime = now
        PlatformHaptics.trigger(.selection)
    }

    private func triggerActiveTabReTapHaptic() {
        let now = ProcessInfo.processInfo.systemUptime

        guard now - lastActiveTabTapTime >= 0.35 else { return }
        lastActiveTabTapTime = now
        PlatformHaptics.trigger(.light)
    }

    private func switchCompactTab(to category: AppFilterCategory) {
        let oldCategory = activeCompactTab
        if oldCategory != category {
            triggerTabSelectionHaptic()
            let oldIndex = compactTabIndex(oldCategory)
            let newIndex = compactTabIndex(category)
            tabTransitionDirection = newIndex > oldIndex ? .forward : .backward
            if !searchText.isEmpty {
                searchText = ""
            }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                selectedFilter = category
            }
            tabBounceTrigger[category, default: 0] += 1
        } else {
            triggerActiveTabReTapHaptic()
            tabBounceTrigger[category, default: 0] += 1
        }
    }

    private var compactTabContentView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let currentIdx = compactTabIndex(activeCompactTab)
            let slideDistance = min(width * 0.65, 260)

            ZStack {
                ForEach(compactTabCategories) { tab in
                    let tabIdx = compactTabIndex(tab)
                    let offset: CGFloat = tabIdx == currentIdx ? 0 : (tabIdx < currentIdx ? -slideDistance : slideDistance)

                    NavigationStack {
                        detailMasterView(isCompact: true, tabCategory: tab)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: offset)
                    .opacity(tabIdx == currentIdx ? 1.0 : 0.0)
                    .allowsHitTesting(tabIdx == currentIdx)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.80), value: activeCompactTab)
            .simultaneousGesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        let horiz = value.translation.width
                        let vert = value.translation.height
                        guard abs(horiz) > abs(vert) * 1.5, abs(horiz) > 40 else { return }
                        if horiz < 0 {
                            if currentIdx < compactTabCategories.count - 1 {
                                switchCompactTab(to: compactTabCategories[currentIdx + 1])
                            }
                        } else {
                            if currentIdx > 0 {
                                switchCompactTab(to: compactTabCategories[currentIdx - 1])
                            }
                        }
                    }
            )
        }
    }

    private func compactTabTitle(for category: AppFilterCategory) -> String {
        switch category {
        case .tomorrow: return "Báo bài"
        case .allUpcoming: return "Sắp tới"
        case .completed: return "Đã xong"
        case .notes: return "Ghi chú"
        default: return category.rawValue
        }
    }

    private func compactTabIcon(for category: AppFilterCategory) -> String {
        switch category {
        case .tomorrow: return "calendar.badge.clock"
        case .allUpcoming: return "tray.fill"
        case .completed: return "checkmark.seal.fill"
        case .notes: return "square.and.pencil"
        default: return "circle"
        }
    }

    private func compactTabBadgeCount(for category: AppFilterCategory, upcomingBadge: Int) -> Int {
        switch category {
        case .tomorrow: return buckets.tomorrowPendingCount
        case .allUpcoming: return upcomingBadge
        case .completed: return 0
        case .notes: return pendingNotesCount
        default: return 0
        }
    }

    private var compactCustomTabBar: some View {
        let upcomingBadge = buckets.allUpcomingPendingCount + buckets.pastPendingCount
        let barHeight: CGFloat = isLandscapePhone ? 40 : 52
        let trackHeight: CGFloat = isLandscapePhone ? 34 : 46
        let trackCornerRadius: CGFloat = isLandscapePhone ? 13 : 15
        let trackPadding: CGFloat = 2.5
        let thumbHeight = trackHeight - trackPadding * 2
        let thumbCornerRadius: CGFloat = isLandscapePhone ? 10.5 : 12.5
        let currentIdx = compactTabIndex(activeCompactTab)
        let tabCount = compactTabCategories.count

        return VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            GeometryReader { proxy in
                let availableWidth = proxy.size.width
                let horizontalInset: CGFloat = isLandscapePhone ? 16 : 10
                let trackWidth = max(0, availableWidth - horizontalInset * 2)
                let innerTrackWidth = max(0, trackWidth - trackPadding * 2)
                let tabWidth = tabCount > 0 ? innerTrackWidth / CGFloat(tabCount) : 0

                ZStack(alignment: .leading) {

                    RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
                        .fill(Color.platformSubtleFill.opacity(colorScheme == .dark ? 0.38 : 0.22))

                    RoundedRectangle(cornerRadius: thumbCornerRadius, style: .continuous)
                        .fill(Color.platformControlBackground)
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08),
                            radius: 3.5,
                            x: 0,
                            y: 1.5
                        )
                        .frame(width: tabWidth, height: thumbHeight)
                        .offset(x: trackPadding + CGFloat(currentIdx) * tabWidth)
                        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: currentIdx)

                    HStack(spacing: 0) {
                        ForEach(compactTabCategories) { tab in
                            let isSelected = (activeCompactTab == tab)
                            CompactTabBarSliderItem(
                                category: tab,
                                title: compactTabTitle(for: tab),
                                icon: compactTabIcon(for: tab),
                                badgeCount: compactTabBadgeCount(for: tab, upcomingBadge: upcomingBadge),
                                isSelected: isSelected,
                                bounce: tabBounceTrigger[tab, default: 0],
                                isLandscapePhone: isLandscapePhone,
                                iconColor: isSelected ? categoryIconColor(tab) : Color.platformTextSecondary,
                                textColor: isSelected ? Color.platformTextPrimary : Color.platformTextSecondary
                            )
                            .frame(width: tabWidth, height: thumbHeight)
                        }
                    }
                    .padding(trackPadding)
                }
                .frame(width: trackWidth, height: trackHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let relativeX = gesture.location.x - horizontalInset - trackPadding
                            guard tabWidth > 0 else { return }
                            let rawIdx = Int(relativeX / tabWidth)
                            let clampedIdx = min(max(rawIdx, 0), tabCount - 1)
                            let target = compactTabCategories[clampedIdx]
                            if target != activeCompactTab {
                                dragSwitchedTabInCurrentGesture = true
                                switchCompactTab(to: target)
                            }
                        }
                        .onEnded { gesture in
                            let relativeX = gesture.location.x - horizontalInset - trackPadding
                            guard tabWidth > 0 else { return }
                            let rawIdx = Int(relativeX / tabWidth)
                            let clampedIdx = min(max(rawIdx, 0), tabCount - 1)
                            let target = compactTabCategories[clampedIdx]
                            if !dragSwitchedTabInCurrentGesture {
                                if target == activeCompactTab && abs(gesture.translation.width) < 8 {
                                    triggerActiveTabReTapHaptic()
                                    tabBounceTrigger[target, default: 0] += 1
                                }
                            }
                            dragSwitchedTabInCurrentGesture = false
                        }
                )
            }
            .frame(height: barHeight)
            .padding(.top, isLandscapePhone ? 1 : 3)
            .padding(.bottom, isLandscapePhone ? 1 : 3)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private struct CompactTabBarSliderItem: View {
        let category: AppFilterCategory
        let title: String
        let icon: String
        let badgeCount: Int
        let isSelected: Bool
        let bounce: Int
        let isLandscapePhone: Bool
        let iconColor: Color
        let textColor: Color

        @State private var bounceScale: CGFloat = 1.0
        @State private var bounceOffset: CGFloat = 0.0

        var body: some View {
            let iconSize: CGFloat = isLandscapePhone ? 15 : 18
            let textSize: CGFloat = isLandscapePhone ? 9.5 : 10.5

            VStack(spacing: isLandscapePhone ? 1 : 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(iconColor)
                        .symbolEffect(.bounce.up.byLayer, options: .speed(1.2), value: bounce)
                        .scaleEffect(bounceScale * (isSelected ? 1.06 : 1.0))
                        .offset(y: bounceOffset)
                        .frame(width: 28, height: isLandscapePhone ? 16 : 20)
                        .onChange(of: bounce) { _, _ in
                            withAnimation(.spring(response: 0.16, dampingFraction: 0.42)) {
                                bounceScale = 1.18
                                bounceOffset = -3.2
                            }
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.58).delay(0.10)) {
                                bounceScale = 1.0
                                bounceOffset = 0.0
                            }
                        }

                    if badgeCount > 0 {
                        Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(iconColor)
                            )
                            .offset(x: 9, y: -4)
                            .contentTransition(.numericText())
                    }
                }

                Text(title)
                    .font(.system(size: textSize, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isSelected)
        }
    }

    @ViewBuilder
    private var compactAppView: some View {
        compactTabContentView
            .safeAreaInset(edge: .bottom, spacing: 0) {
                compactCustomTabBar
            }
            .sheet(isPresented: $showCompactCourseFilterSheet) {
                compactCourseFilterSheetView
            }
            .sheet(isPresented: $showMobileDetailSheet) {
                NavigationStack {
                    homeworkReaderPane
                        .navigationTitle(selectedCoursework?.id.hasPrefix("note_") == true ? "Chi tiết việc cần làm" : "Chi tiết bài tập")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button {
                                    triggerHapticFeedback()
                                    showMobileDetailSheet = false
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
                    let oldIdx = categoryOrder(selectedFilter)
                    let newIdx = categoryOrder(val)
                    if oldIdx != newIdx {
                        tabTransitionDirection = newIdx > oldIdx ? .forward : .backward
                    }
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        selectedFilter = val
                    }
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
                    Button(allSelected ? "Bỏ chọn hết" : "Tất cả") {
                        toggleAllCourses()
                    }
                    .buttonStyle(.plain)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(allSelected ? Color.secondary : Color.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule().fill(allSelected ? Color.platformControlBackground : Color.blue.opacity(0.10))
                    )
                    .overlay(
                        Capsule().stroke(allSelected ? Color.platformCardBorder : Color.blue.opacity(0.24), lineWidth: 1)
                    )
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
                let oldIdx = categoryOrder(selectedFilter)
                let newIdx = categoryOrder(category)
                if oldIdx != newIdx {
                    tabTransitionDirection = newIdx > oldIdx ? .forward : .backward
                }
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
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
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill(iconBgColor)
                    .frame(width: 26, height: 26)

                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconFgColor)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
            }

            Text(category.rawValue)
                .font(.system(size: 14.5, weight: isSelected ? .bold : .medium))
                .foregroundStyle(textFgColor)
                .lineLimit(1)

            Spacer()

            if let count, count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        Capsule()
                            .fill(badgeBgColor)
                            .shadow(color: badgeShadowColor, radius: 2, x: 0, y: 1)
                    )
                    .foregroundStyle(badgeFgColor)
                    .scaleEffect(isSelected ? 1.06 : 1.0)
            }
        }
        .padding(.vertical, 2.5)
        .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isSelected)
    }

    private func categoryOrder(_ category: AppFilterCategory) -> Int {
        switch category {
        case .tomorrow: return 0
        case .todayAndTomorrow: return 1
        case .allUpcoming: return 2
        case .past: return 3
        case .completed: return 4
        case .notes: return 5
        case .widgetPreview: return 6
        }
    }

    private var macOSTabTransition: AnyTransition {
        let offset: CGFloat = 16
        let moveX = tabTransitionDirection == .forward ? offset : -offset
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: moveX)),
            removal: .opacity.combined(with: .offset(x: -moveX))
        )
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

            detailBodyContent(for: activeCategory, isCompact: isCompact)
        }
        .navigationTitle(activeCategory.rawValue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                                    showMobileDetailSheet = false
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
                    Task { @MainActor in
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
                    showSettingsModal = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Cài đặt tài khoản & dữ liệu mẫu")
            }
        }
    }

    @ViewBuilder
    private func detailBodyContent(for activeCategory: AppFilterCategory, isCompact: Bool) -> some View {
        #if os(macOS)
        ZStack {
            detailCategoryView(for: activeCategory, isCompact: isCompact)
                .id(activeCategory)
                .transition(macOSTabTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: activeCategory)
        #else
        if isCompact {
            detailCategoryView(for: activeCategory, isCompact: isCompact)
        } else {
            ZStack {
                detailCategoryView(for: activeCategory, isCompact: isCompact)
                    .id(activeCategory)
                    .transition(macOSTabTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: activeCategory)
        }
        #endif
    }

    @ViewBuilder
    private func detailCategoryView(for activeCategory: AppFilterCategory, isCompact: Bool) -> some View {
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
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button {
                                        triggerHapticFeedback()
                                        showMobileDetailSheet = false
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
                                Button {
                                    showMobileDetailSheet = false
                                } label: {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.green))
                                }
                                .accessibilityLabel("Xong")
                            }
                        }
                }
                .frame(minWidth: 420, minHeight: 460)
            }
            #endif
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
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.platformTextTertiary)
                Text(formattedCompactCurrentDate())
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.platformTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(0)

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                    Button {
                        triggerHapticFeedback()
                        showCompactCourseFilterSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Lớp (\(courses.filter(\.isSelectedForWidget).count)/\(courses.count))")
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.platformTextSecondary)
                        .padding(.horizontal, 9.5)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.platformControlBackground)
                        )
                        .overlay(
                            Capsule().stroke(Color.platformCardBorder, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(SpringPressButtonStyle(scale: 0.94, pressedOpacity: 0.88))
                    .fixedSize()

                    if category == .widgetPreview {
                        HStack(spacing: 4) {
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Xem trước")
                                .font(.system(size: 13.5, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 9.5)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.purple.opacity(0.10))
                        )
                        .fixedSize()
                    } else if category == .notes {
                        if pendingNotesCount == 0 && totalIndependentNotesCount > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("Đã xong hết")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9.5)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color.green.opacity(0.12))
                            )
                            .fixedSize()
                        } else {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6.5, height: 6.5)
                                Text("\(pendingNotesCount) việc cần làm")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                                    .contentTransition(.numericText())
                            }
                            .padding(.horizontal, 9.5)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(categoryIconColor(category).opacity(0.10))
                            )
                            .fixedSize()
                        }
                    } else {
                        let pendingCount = categoryPendingCount(category)
                        if pendingCount > 0 {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryIconColor(category))
                                    .frame(width: 6.5, height: 6.5)
                                Text("\(pendingCount) cần nộp")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(categoryIconColor(category))
                                    .lineLimit(1)
                                    .contentTransition(.numericText())
                            }
                            .padding(.horizontal, 9.5)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(categoryIconColor(category).opacity(0.10))
                            )
                            .fixedSize()
                        } else if categoryHasItems(category) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Đã nộp hết")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                            .padding(.horizontal, 9.5)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.12))
                            )
                            .fixedSize()
                        }
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
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(categoryIconColor(category).opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: category.icon)
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundStyle(categoryIconColor(category))
                        .contentTransition(.symbolEffect(.replace))
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: category)

                VStack(alignment: .leading, spacing: 2.5) {
                    Text(category.rawValue)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.platformTextPrimary)
                        .contentTransition(.interpolate)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.platformTextTertiary)
                        Text(formattedCurrentDate())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.platformTextSecondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if category == .widgetPreview {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("Cấu hình & Xem trước Widget")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.purple)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.purple.opacity(0.10))
                    )
                    .fixedSize()
                } else if category == .notes {
                    if pendingNotesCount == 0 && totalIndependentNotesCount > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.green)
                            Text("Đã xong hết")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.green)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(Color.green.opacity(0.12))
                        )
                        .fixedSize()
                    } else {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(categoryIconColor(category))
                                .frame(width: 6.5, height: 6.5)
                            Text("\(pendingNotesCount) việc cần làm")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(categoryIconColor(category))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(categoryIconColor(category).opacity(0.10))
                        )
                        .fixedSize()
                    }
                } else {
                    let pendingCount = categoryPendingCount(category)
                    if pendingCount > 0 {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(categoryIconColor(category))
                                .frame(width: 6.5, height: 6.5)
                            Text("\(pendingCount) bài cần nộp")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(categoryIconColor(category))
                                .lineLimit(1)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(categoryIconColor(category).opacity(0.10))
                        )
                        .fixedSize()
                    } else if categoryHasItems(category) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Đã nộp tất cả")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(Color(red: 0.12, green: 0.62, blue: 0.35).opacity(0.12))
                        )
                        .fixedSize()
                    }
                }

                if authService.isAuthenticated {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.blue)
                        Text(authService.currentUserEmail ?? "Đã kết nối")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.platformTextSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.platformControlBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.platformCardBorder, lineWidth: 1)
                    )
                    .fixedSize()
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
            isWide: isWide,
            hasNote: noteCourseworkIds.contains(item.id),
            onSelect: { cmdPressed in
                handleItemTap(item, commandPressed: cmdPressed, isWide: isWide)
            },
            onToggleCompletion: {
                toggleCompletion(for: item)
            }
        )
        .equatable()
        .id(item.id)
    }

    @ViewBuilder
    private func assignmentListPane(isWide: Bool = true, category: AppFilterCategory? = nil) -> some View {
        let activeCategory = category ?? selectedFilter
        let list = currentFilteredList(for: activeCategory)
        VStack(spacing: 0) {
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
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
                        .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color(red: 0.12, green: 0.62, blue: 0.35))
                    Text("\(list.count) bài đã hoàn thành")
                        .font(.system(size: 13, weight: .semibold))
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
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.white : Color.platformTextSecondary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? Color.blue : Color.platformControlBackground)
                                        )
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

                    HStack(spacing: 6) {
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
                            .background(
                                Capsule().fill(allSelectedDone ? Color.orange : Color(red: 0.12, green: 0.62, blue: 0.35))
                            )
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
                        .background(
                            Capsule().fill(Color.platformControlBackground)
                        )
                        .overlay(
                            Capsule().stroke(Color.platformCardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.platformControlBackground)
                )
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
                                TomorrowHeroBanner()
                                TomorrowProgressHeroCard(
                                    totalCount: buckets.tomorrow.count,
                                    completedCount: max(0, buckets.tomorrow.count - buckets.tomorrowPendingCount),
                                    hasTomorrowTasks: !buckets.tomorrowStrict.isEmpty,
                                    hasTodayTasks: !buckets.today.isEmpty,
                                    shareText: formattedBaoBaiShareText
                                )
                            }

                            let groups = tomorrowGroups(for: list)

                            if !groups.groupedPending.isEmpty {
                                ForEach(groups.groupedPending, id: \.courseName) { group in
                                    SubjectGroupHeaderRow(courseName: group.courseName, count: group.items.count)

                                    ForEach(group.items) { item in
                                        assignmentItemRow(item: item, isWide: isWide)
                                    }
                                }
                            }

                            if !groups.completedItems.isEmpty {
                                CompletedSectionHeaderRow(count: groups.completedItems.count)

                                ForEach(groups.completedItems) { item in
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
                        triggerHapticFeedback()
                        await apiService.syncAll()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            refreshData()
                        }
                    }
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isSearchFocused {
                            isSearchFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                )
                #endif
                }
            }
        }
        .background(
            Color.platformWindowBackground
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSearchFocused {
                        isSearchFocused = false
                    }
                    #if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                }
        )
    }

    private var formattedBaoBaiShareText: String {
        if !cachedBaoBaiShareText.isEmpty {
            return cachedBaoBaiShareText
        }
        return BaoBaiShareHelper.formatBaoBaiText(
            items: buckets.tomorrow,
            hasTomorrowTasks: !buckets.tomorrowStrict.isEmpty,
            hasTodayTasks: !buckets.today.isEmpty
        )
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
                    showMobileDetailSheet = false
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
                    let availableWidth = max(0, cardGeometry.size.width - 32)
                    let widgetWidth: CGFloat = selectedPreviewFamily == .small ? 155 : 325
                    let widgetHeight: CGFloat = selectedPreviewFamily == .large ? 325 : 155
                    let previewScale = min(1, availableWidth / widgetWidth)
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
                            case .medium:
                                MediumWidgetView(courseworkList: itemsForPreview)
                            case .large:
                                LargeWidgetView(courseworkList: itemsForPreview)
                            }
                        }
                        .frame(width: widgetWidth, height: widgetHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
                        .scaleEffect(previewScale)
                        .frame(width: widgetWidth * previewScale, height: widgetHeight * previewScale)
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
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.platformControlBackground)
            )
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.platformControlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.platformCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    private var settingsSheetView: some View {
        SettingsSheetView(
            authService: authService,
            apiService: apiService,
            reminderService: reminderService,
            updateService: updateService,
            isPresented: $showSettingsModal,
            showLogoutConfirmation: $showLogoutConfirmation,
            isDemoMode: $isDemoMode,
            clientIdInput: $clientIdInput,
            isAdvancedSettingsExpanded: $isAdvancedSettingsExpanded,
            onRefreshData: {
                refreshData()
            },
            onAutoSelectFirstItem: {
                autoSelectFirstItem()
            },
            onTriggerHaptic: {
                triggerHapticFeedback()
            },
            onShowToast: { title, subtitle, icon, tint in
                showToast(title: title, subtitle: subtitle, icon: icon, tint: tint)
            },
            onStartGoogleLogin: {
                startGoogleLogin()
            }
        )
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

        toastDismissTask = Task { @MainActor in
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
            if selectedCourseworkIds.count > 1, let current = selectedCoursework {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedCourseworkIds = [current.id]
                }
            } else {
                handleDeselectAll()
            }
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
        self.noteCourseworkIds = Set(personalNotes.lazy.filter {
            !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !$0.checklist.isEmpty
        }.compactMap(\.courseworkId))
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
            if let updated = currentFilteredList.first(where: { $0.id == current.id }) {
                self.selectedCoursework = updated
            } else if let updated = allCoursework.first(where: { $0.id == current.id }) {
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
            let trimmedContent = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if let cwId = note.courseworkId, !cwId.isEmpty, trimmedContent.isEmpty, note.checklist.isEmpty {
                current.removeAll { $0.id == note.id }
            } else if let index = current.firstIndex(where: { $0.id == note.id }) {
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

    private func reconcileSelectionAfterFilterChange() {
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
            let availableList = currentFilteredList
            let availableIds = Set(availableList.map(\.id))
            let retainedSelectedIds = selectedCourseworkIds.intersection(availableIds)
            selectedCourseworkIds = retainedSelectedIds

            if let current = selectedCoursework {
                if retainedSelectedIds.contains(current.id) {
                    selectedCoursework = availableList.first(where: { $0.id == current.id })
                } else if let firstRemainingId = retainedSelectedIds.first {
                    selectedCoursework = availableList.first(where: { $0.id == firstRemainingId })
                } else {
                    selectedCoursework = nil
                }
            } else if let firstRemainingId = retainedSelectedIds.first {
                selectedCoursework = availableList.first(where: { $0.id == firstRemainingId })
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
        Task { @MainActor in
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
