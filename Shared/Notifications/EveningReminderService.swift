import Foundation
@preconcurrency import UserNotifications
import Combine

@MainActor
public final class EveningReminderService: ObservableObject {
    public static let shared = EveningReminderService()

    public nonisolated static let notificationIdentifier = "com.phucta.classroom.evening_bao_bai_reminder"
    private let enabledKey = "classroom_evening_reminder_enabled"
    private let hourKey = "classroom_evening_reminder_hour"
    private let minuteKey = "classroom_evening_reminder_minute"
    private var scheduleTask: Task<Void, Never>?

    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
            if isEnabled {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    @Published public var reminderHour: Int {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: hourKey)
            if isEnabled {
                scheduleReminder()
            }
        }
    }

    @Published public var reminderMinute: Int {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: minuteKey)
            if isEnabled {
                scheduleReminder()
            }
        }
    }

    @Published public var isAuthorized: Bool = false

    private init() {
        let hasConfigured = UserDefaults.standard.object(forKey: enabledKey) != nil
        self.isEnabled = hasConfigured ? UserDefaults.standard.bool(forKey: enabledKey) : true
        self.reminderHour = UserDefaults.standard.object(forKey: hourKey) != nil ? UserDefaults.standard.integer(forKey: hourKey) : 20
        self.reminderMinute = UserDefaults.standard.object(forKey: minuteKey) != nil ? UserDefaults.standard.integer(forKey: minuteKey) : 0

        Task {
            await checkAuthorizationStatus()
        }
    }

    @MainActor
    public func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
        self.isAuthorized = authorized
        return authorized
    }

    @MainActor
    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            if granted && isEnabled {
                await performScheduleReminder()
            }
            return granted
        } catch {
            self.isAuthorized = false
            return false
        }
    }

    public func setReminderTime(hour: Int, minute: Int) {
        let clampedHour = max(0, min(23, hour))
        let clampedMinute = max(0, min(59, minute))
        guard clampedHour != self.reminderHour || clampedMinute != self.reminderMinute else { return }
        self.reminderHour = clampedHour
        self.reminderMinute = clampedMinute
    }

    public func scheduleReminder() {
        guard isEnabled else {
            cancelReminder()
            return
        }

        scheduleTask?.cancel()
        scheduleTask = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            await self.performScheduleReminder()
        }
    }

    public func performScheduleReminder() async {
        guard isEnabled else {
            cancelReminder()
            return
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = buildNotificationContent()

        let calendar = Calendar.current
        let now = Date()
        var targetDateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        targetDateComponents.hour = reminderHour
        targetDateComponents.minute = reminderMinute
        targetDateComponents.second = 0

        guard var targetDate = calendar.date(from: targetDateComponents) else { return }
        if targetDate <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }

        let scheduleComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: scheduleComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Lỗi lên lịch thông báo Báo bài buổi tối: \(error.localizedDescription)")
        }
    }

    public func updateReminderContent() {
        guard isEnabled else { return }
        scheduleReminder()
    }

    public func cancelReminder() {
        scheduleTask?.cancel()
        scheduleTask = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    public func previewNotificationText() -> String {
        let (title, body) = generateMessageData()
        return "\(title): \(body)"
    }

    private func generateMessageData() -> (title: String, body: String) {
        let allItems = ClassroomStorage.shared.getTomorrowCoursework(includeCompleted: true)
        let strictlyTomorrowItems = allItems.filter { $0.isDueTomorrow || $0.isDueToday }
        let pendingItems = strictlyTomorrowItems.filter { !$0.isCompleted }

        if pendingItems.isEmpty {
            if strictlyTomorrowItems.isEmpty {
                return (
                    title: "Báo bài ngày mai",
                    body: "Không có bài tập nào cần nộp ngày mai."
                )
            } else {
                return (
                    title: "Báo bài ngày mai",
                    body: "Tất cả \(strictlyTomorrowItems.count) bài tập ngày mai đều đã hoàn thành."
                )
            }
        } else {
            var subjectSet: [String] = []
            for item in pendingItems {
                let code = SubjectArtHelper.badgeCode(for: item.courseName, title: item.title)
                if !subjectSet.contains(code) {
                    subjectSet.append(code)
                }
            }
            let subjectsStr = subjectSet.isEmpty ? "" : " (\(subjectSet.joined(separator: ", ")))"
            return (
                title: "Báo bài Ngày mai",
                body: "Bạn còn \(pendingItems.count) bài tập cần chuẩn bị cho ngày mai\(subjectsStr). Soạn tập vở thôi nào!"
            )
        }
    }

    private func buildNotificationContent() -> UNMutableNotificationContent {
        let (title, body) = generateMessageData()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}
