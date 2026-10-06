import WidgetKit
import SwiftUI

public struct ClassroomEntry: TimelineEntry {
    public let date: Date
    public let courseworkList: [Coursework]

    public init(date: Date, courseworkList: [Coursework]) {
        self.date = date
        self.courseworkList = courseworkList
    }

    public var hasUrgentTask: Bool {
        courseworkList.first?.isUrgent == true
    }
}

public struct ClassroomTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> ClassroomEntry {
        let items = ClassroomStorage.mockCoursework.filter { $0.isDueTodayOrTomorrow }
        return ClassroomEntry(date: Date(), courseworkList: items)
    }

    public func getSnapshot(in context: Context, completion: @escaping (ClassroomEntry) -> Void) {
        let items = ClassroomStorage.shared.getTodayAndTomorrowCoursework()
        let entry = ClassroomEntry(date: Date(), courseworkList: items)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<ClassroomEntry>) -> Void) {
        let items = ClassroomStorage.shared.getTodayAndTomorrowCoursework()
        let currentDate = Date()
        let currentEntry = ClassroomEntry(date: currentDate, courseworkList: items)

        var nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)

        if let mostUrgentDueDate = items.first?.dueDate, mostUrgentDueDate > currentDate, mostUrgentDueDate < nextRefresh {
            nextRefresh = mostUrgentDueDate
        }

        let timeline = Timeline(entries: [currentEntry], policy: .after(nextRefresh))
        completion(timeline)
    }
}
