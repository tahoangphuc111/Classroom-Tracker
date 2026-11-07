import Foundation

public enum BaoBaiShareHelper {
    public static func formatHeaderDate(
        for date: Date,
        calendar: Calendar = ClassroomDateFormatters.gregorianCalendar
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE, 'ngày' dd/MM"
        var dateStr = formatter.string(from: date)
        if let firstChar = dateStr.first {
            dateStr = firstChar.uppercased() + dateStr.dropFirst()
        }
        return dateStr
    }

    public static func targetDate(
        items: [Coursework],
        hasTomorrowTasks: Bool,
        hasTodayTasks: Bool,
        now: Date = Date(),
        calendar: Calendar = ClassroomDateFormatters.gregorianCalendar
    ) -> Date {
        if hasTomorrowTasks {
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        } else if hasTodayTasks {
            return now
        } else {
            return items.first?.dueDate ?? (calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        }
    }

    public static func targetDayLabel(hasTomorrowTasks: Bool, hasTodayTasks: Bool) -> String {
        if hasTomorrowTasks {
            return "NGÀY MAI"
        } else if hasTodayTasks {
            return "HÔM NAY"
        } else {
            return "SẮP TỚI"
        }
    }

    public static func formatBaoBaiText(
        items: [Coursework],
        hasTomorrowTasks: Bool = false,
        hasTodayTasks: Bool = false,
        now: Date = Date(),
        calendar: Calendar = ClassroomDateFormatters.gregorianCalendar
    ) -> String {
        let label = targetDayLabel(hasTomorrowTasks: hasTomorrowTasks, hasTodayTasks: hasTodayTasks)
        let date = targetDate(items: items, hasTomorrowTasks: hasTomorrowTasks, hasTodayTasks: hasTodayTasks, now: now, calendar: calendar)
        return formatBaoBaiText(items: items, targetDate: date, targetDayLabel: label, calendar: calendar)
    }

    public static func formatBaoBaiText(
        items: [Coursework],
        targetDate: Date,
        targetDayLabel: String,
        calendar: Calendar = ClassroomDateFormatters.gregorianCalendar
    ) -> String {
        let dateStr = formatHeaderDate(for: targetDate, calendar: calendar)

        if items.isEmpty {
            return """
            BÁO BÀI \(targetDayLabel) (\(dateStr))

            Hiện tại không có bài tập nào cần làm.

            ---
            Classroom Tracker
            """
        }

        let totalCount = items.count
        var completedCount = 0
        var lines = [
            "BÁO BÀI \(targetDayLabel) (\(dateStr))\n"
        ]
        for (index, item) in items.enumerated() {
            if item.isCompleted {
                completedCount += 1
            }
            let courseTag = !item.courseName.isEmpty ? "[\(item.courseName)]" : "[Chung]"
            let dueStr: String
            if let dueDate = item.dueDate {
                if item.isDueTomorrow {
                    dueStr = "Hạn: \(item.timeOnlyString)"
                } else {
                    let shortDay = ClassroomDateFormatters.shortDate.string(from: dueDate)
                    dueStr = "Hạn: \(item.timeOnlyString) (\(shortDay))"
                }
            } else {
                dueStr = "Không có hạn nộp"
            }
            let statusSuffix = item.isCompleted ? " (Đã xong)" : ""
            lines.append("\(index + 1). \(courseTag) \(item.title) — \(dueStr)\(statusSuffix)")
        }
        lines.append("\n---\nTiến độ: \(completedCount)/\(totalCount) bài hoàn thành\nClassroom Tracker")
        return lines.joined(separator: "\n")
    }
}
