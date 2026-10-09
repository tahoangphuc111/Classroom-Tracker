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
        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        if !real.isEmpty {
            return ClassroomEntry(date: Date(), courseworkList: real, isLoggedIn: true)
        }
        return ClassroomEntry(date: Date(), courseworkList: ClassroomStorage.mockCoursework, isLoggedIn: true)
    }

    public func getSnapshot(in context: Context, completion: @escaping (ClassroomEntry) -> Void) {
        let widgetLogger = Logger(subsystem: "com.phucta.ClassroomTracker.widget", category: "timeline")
        let isLoggedIn = ClassroomStorage.shared.hasUserLoggedIn
        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        widgetLogger.notice("getSnapshot: isPreview=\(context.isPreview), real count=\(real.count), IDs: \(real.map(\.id).joined(separator: ","), privacy: .public)")
        if !real.isEmpty {
            completion(ClassroomEntry(date: Date(), courseworkList: real, isLoggedIn: isLoggedIn))
            return
        }

        if isLoggedIn {
            completion(ClassroomEntry(date: Date(), courseworkList: [], isLoggedIn: true))
            return
        }

        if context.isPreview {
            let mock = ClassroomStorage.mockCoursework
            let tomorrow = mock.filter { $0.isDueTomorrow }
            let items = tomorrow.isEmpty ? mock : tomorrow
            completion(ClassroomEntry(date: Date(), courseworkList: items, isLoggedIn: true))
            return
        }

        completion(ClassroomEntry(date: Date(), courseworkList: [], isLoggedIn: false))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<ClassroomEntry>) -> Void) {
        let widgetLogger = Logger(subsystem: "com.phucta.ClassroomTracker.widget", category: "timeline")
        let isLoggedIn = ClassroomStorage.shared.hasUserLoggedIn
        let real = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        let displayItems: [Coursework] = real
        widgetLogger.notice("getTimeline: \(displayItems.count) items, IDs: \(displayItems.map(\.id).joined(separator: ","), privacy: .public)")

        let currentDate = Date()
        let currentEntry = ClassroomEntry(date: currentDate, courseworkList: displayItems, isLoggedIn: isLoggedIn)

        var nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)

        // Refresh at midnight so due dates update on day rollover
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        if let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
           startOfTomorrow > currentDate, startOfTomorrow < nextRefresh {
            nextRefresh = startOfTomorrow
        }

        if let earliestDueDate = displayItems.compactMap(\.dueDate).filter({ $0 > currentDate }).min(),
           earliestDueDate < nextRefresh {
            nextRefresh = earliestDueDate
        }

        let timeline = Timeline(entries: [currentEntry], policy: .after(nextRefresh))
        completion(timeline)
    }
}
