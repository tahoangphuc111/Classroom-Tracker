import WidgetKit
import SwiftUI
import os

public struct ClassroomEntry: TimelineEntry {
    public let date: Date
    public let courseworkList: [Coursework]
    public let isLoggedIn: Bool

    public init(date: Date, courseworkList: [Coursework], isLoggedIn: Bool = true) {
        self.date = date
        self.courseworkList = courseworkList
        self.isLoggedIn = isLoggedIn
    }

    public var hasUrgentTask: Bool {
        courseworkList.contains { !$0.isCompleted && $0.isUrgent }
    }
}

public struct ClassroomTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> ClassroomEntry {
        ClassroomStorage.shared.invalidateMemoryCache()
        let isLoggedIn = ClassroomStorage.shared.hasUserLoggedIn
        guard isLoggedIn else {
            return ClassroomEntry(date: Date(), courseworkList: [], isLoggedIn: false)
        }
        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        return ClassroomEntry(date: Date(), courseworkList: real, isLoggedIn: true)
    }

    public func getSnapshot(in context: Context, completion: @escaping (ClassroomEntry) -> Void) {
        ClassroomStorage.shared.invalidateMemoryCache()
        let widgetLogger = Logger(subsystem: "com.phucta.ClassroomTracker.widget", category: "timeline")
        let isLoggedIn = ClassroomStorage.shared.hasUserLoggedIn
        widgetLogger.notice("getSnapshot: isPreview=\(context.isPreview), isLoggedIn=\(isLoggedIn)")

        guard isLoggedIn else {
            completion(ClassroomEntry(date: Date(), courseworkList: [], isLoggedIn: false))
            return
        }

        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        if !real.isEmpty {
            completion(ClassroomEntry(date: Date(), courseworkList: real, isLoggedIn: true))
            return
        }

        if context.isPreview {
            let mock = ClassroomStorage.mockCoursework
            let tomorrow = mock.filter { $0.isDueTomorrow }
            let items = tomorrow.isEmpty ? mock : tomorrow
            completion(ClassroomEntry(date: Date(), courseworkList: items, isLoggedIn: true))
            return
        }

        completion(ClassroomEntry(date: Date(), courseworkList: [], isLoggedIn: true))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<ClassroomEntry>) -> Void) {
        ClassroomStorage.shared.invalidateMemoryCache()
        let widgetLogger = Logger(subsystem: "com.phucta.ClassroomTracker.widget", category: "timeline")
        let isLoggedIn = ClassroomStorage.shared.hasUserLoggedIn
        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        let displayItems: [Coursework] = isLoggedIn ? real : []
        widgetLogger.notice("getTimeline: \(displayItems.count) items, IDs: \(displayItems.map(\.id).joined(separator: ","), privacy: .public)")

        let currentDate = Date()
        let currentEntry = ClassroomEntry(date: currentDate, courseworkList: displayItems, isLoggedIn: isLoggedIn)

        let calendar = Calendar.autoupdatingCurrent

        guard isLoggedIn else {
            let nextRefresh = currentDate.addingTimeInterval(900)
            completion(Timeline(entries: [currentEntry], policy: .after(nextRefresh)))
            return
        }

        var nextRefresh = calendar.date(byAdding: .minute, value: 45, to: currentDate) ?? currentDate.addingTimeInterval(2700)

        let startOfToday = calendar.startOfDay(for: currentDate)
        if let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
           startOfTomorrow > currentDate, startOfTomorrow < nextRefresh {
            nextRefresh = startOfTomorrow.addingTimeInterval(1)
        }

        if let earliestDueDate = displayItems.compactMap(\.dueDate).filter({ $0 > currentDate }).min(),
           earliestDueDate < nextRefresh {
            nextRefresh = earliestDueDate.addingTimeInterval(1)
        }

        let minimumRefreshDate = currentDate.addingTimeInterval(900)
        if nextRefresh < minimumRefreshDate {
            nextRefresh = minimumRefreshDate
        }

        let timeline = Timeline(entries: [currentEntry], policy: .after(nextRefresh))
        completion(timeline)
    }
}
