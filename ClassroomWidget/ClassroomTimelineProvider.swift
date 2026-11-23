import WidgetKit
import SwiftUI

struct ClassroomEntry: TimelineEntry {
    enum State {
        case signedOut, needsSync, storageUnavailable, ready
    }

    let date: Date
    var courseworkList: [Coursework] = []
    let state: State
}

struct ClassroomTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClassroomEntry {
        ClassroomEntry(date: Date(), state: .needsSync)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassroomEntry) -> Void) {
        completion(loadEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassroomEntry>) -> Void) {
        let currentDate = Date()
        let entry = loadEntry(at: currentDate)
        let minimumRefreshDate = currentDate.addingTimeInterval(15 * 60)
        guard entry.state == .ready else {
            completion(Timeline(entries: [entry], policy: .after(minimumRefreshDate)))
            return
        }

        let calendar = ClassroomDateFormatters.gregorianCalendar
        var nextRefresh = currentDate.addingTimeInterval(45 * 60)
        let startOfToday = calendar.startOfDay(for: currentDate)
        if let midnight = calendar.date(byAdding: .day, value: 1, to: startOfToday), midnight < nextRefresh {
            nextRefresh = midnight.addingTimeInterval(1)
        }
        if let nextDueDate = entry.courseworkList.compactMap(\.dueDate).filter({ $0 > currentDate }).min(), nextDueDate < nextRefresh {
            nextRefresh = nextDueDate.addingTimeInterval(1)
        }

        completion(Timeline(entries: [entry], policy: .after(max(minimumRefreshDate, nextRefresh))))
    }

    func loadEntry(at date: Date) -> ClassroomEntry {
        let storage = ClassroomStorage.shared
        #if os(iOS) || CLASSROOM_TESTING
        guard !ClassroomStorage.appGroupDirectories.isEmpty else {
            return ClassroomEntry(date: date, state: .storageUnavailable)
        }
        guard let snapshot = storage.loadWidgetSnapshot() else {
            return ClassroomEntry(date: date, state: .needsSync)
        }
        guard snapshot.isSignedIn else {
            return ClassroomEntry(date: date, state: .signedOut)
        }
        let items = storage.getTomorrowCoursework(
            filteredItems: snapshot.coursework,
            courses: snapshot.courses,
            personalNotes: snapshot.notes,
            now: date
        )
        let state: ClassroomEntry.State = snapshot.hasSynced || !items.isEmpty ? .ready : .needsSync
        return ClassroomEntry(date: date, courseworkList: items, state: state)
        #else
        storage.invalidateMemoryCache()
        guard storage.hasUserLoggedIn else {
            return ClassroomEntry(date: date, state: .signedOut)
        }
        return ClassroomEntry(date: date, courseworkList: storage.getTomorrowCoursework(), state: .ready)
        #endif
    }
}
