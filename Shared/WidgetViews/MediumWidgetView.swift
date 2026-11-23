import SwiftUI
import WidgetKit

public struct MediumWidgetView: View {
    let courseworkList: [Coursework]
    let isLoggedIn: Bool

    public init(courseworkList: [Coursework], isLoggedIn: Bool = true) {
        self.courseworkList = courseworkList
        self.isLoggedIn = isLoggedIn
    }

    private var sectionHeaderTitle: String {
        let pending = courseworkList.filter { !$0.isCompleted }
        let hasToday = pending.contains(where: \.isDueToday)
        let hasTomorrow = pending.contains(where: \.isDueTomorrow)

        if hasToday && hasTomorrow {
            return "HÔM NAY & MAI"
        } else if hasToday {
            return "HÔM NAY"
        } else if hasTomorrow {
            return "NGÀY MAI"
        } else if pending.contains(where: { ($0.dueDate ?? .distantFuture) < Date() }) {
            return "QUÁ HẠN"
        } else if !pending.isEmpty {
            return "SẮP TỚI"
        } else if courseworkList.contains(where: \.isDueToday) {
            return "HÔM NAY"
        } else {
            return "NGÀY MAI"
        }
    }

    private var activeItems: [Coursework] {
        courseworkList.filter { !$0.isCompleted }
    }

    private var displayItems: [Coursework] {
        if activeItems.isEmpty {
            return courseworkList
        }
        let completed = courseworkList.filter(\.isCompleted)
        return activeItems + completed
    }

    private var characterEmotion: EmberEmotion {
        if activeItems.isEmpty {
            return courseworkList.contains(where: \.isCompleted) ? .celebrating : .sleeping
        } else if activeItems.count >= 4 {
            return .stressed
        } else {
            return .normal
        }
    }

    private var moodBadgeText: String {
        if activeItems.isEmpty {
            return courseworkList.isEmpty ? "Thảnh thơi" : "Hoàn thành"
        } else if activeItems.count >= 4 {
            return "Tập trung"
        } else {
            return "Sẵn sàng"
        }
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            backgroundClouds

            if !isLoggedIn {
                loggedOutMediumView
            } else {
                HStack(spacing: 10) {
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 35))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.20), radius: 0, x: 0, y: 1.5)

                            if activeItems.isEmpty && !courseworkList.isEmpty {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                            } else {
                                Text(sectionHeaderTitle)
                                    .font(WidgetFontSystem.sectionHeader(size: 10.5))
                                    .tracking(0.0)
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 0)

                        ChunkyEmberCharacterView(emotion: characterEmotion, size: 76)
                            .padding(.bottom, 6)
                    }
                    .frame(width: 92)
                    .frame(maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(sectionHeaderTitle)
                                .font(WidgetFontSystem.sectionHeader(size: 11.5))
                                .tracking(0.0)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer(minLength: 4)

                            if activeItems.count > 3 {
                                Text("+\(activeItems.count - 3)")
                                    .font(WidgetFontSystem.statusTag(size: 10))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 6.5)
                                    .padding(.vertical, 2)
                                    .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if !activeItems.isEmpty {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.sectionHeader(size: 10.5))
                                    .foregroundStyle(ChunkyTheme.textMuted)
                            } else if !courseworkList.isEmpty {
                                Image(systemName: "checkmark")
                                    .font(WidgetFontSystem.sectionHeader(size: 10.5))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 11)
                        .padding(.bottom, 4)

                        Rectangle()
                            .fill(ChunkyTheme.editorialHairline)
                            .frame(height: 0.8)
                            .padding(.horizontal, 10)

                        if displayItems.isEmpty {
                            emptyStateView
                                .padding(.horizontal, 11)
                                .frame(maxHeight: .infinity, alignment: .center)
                        } else if displayItems.count == 1, let singleItem = displayItems.first {
                            singleHeroTaskView(item: singleItem)
                        } else {
                            pureTaskListRows
                                .padding(.horizontal, 10)
                                .padding(.top, 2)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(ChunkyTheme.sheetBg)
                            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 14)
                    .padding(.trailing, 16)
                }
            }
        }
        .widgetURL(isLoggedIn ? nil : URL(string: "classroomwidget://login"))
        .unredacted()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loggedOutMediumView: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                ChunkyEmberCharacterView(emotion: .normal, size: 68)

                Text("Báo bài")
                    .font(WidgetFontSystem.sectionHeader(size: 11.5))
                    .foregroundStyle(ChunkyTheme.butterYellow)
            }
            .frame(width: 90)

            VStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ChunkyTheme.pillBlue)

                Text("Chưa đăng nhập")
                    .font(WidgetFontSystem.courseTitle(size: 15))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Chạm để đăng nhập Google Classroom")
                    .font(WidgetFontSystem.meta(size: 12))
                    .foregroundStyle(ChunkyTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ChunkyTheme.sheetBg)
                    .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                    )
            }
            .padding(.vertical, 14)
            .padding(.trailing, 16)
        }
    }

    private var backgroundClouds: some View {
        Canvas { context, size in
            let cloud1 = CGRect(x: size.width - 85, y: 6, width: 68, height: 18)
            context.fill(Path(roundedRect: cloud1, cornerRadius: 9), with: .color(Color.white.opacity(0.16)))

            let cloud2 = CGRect(x: 10, y: 8, width: 44, height: 14)
            context.fill(Path(roundedRect: cloud2, cornerRadius: 7), with: .color(Color.white.opacity(0.12)))
        }
        .allowsHitTesting(false)
    }

    private var emptyStateView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ChunkyTheme.butterYellow.opacity(0.35))
                    .frame(width: 40, height: 40)

                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
            }

            VStack(alignment: .leading, spacing: 2.5) {
                Text(sectionHeaderTitle == "HÔM NAY" ? "Hôm nay hết bài rồi!" : (sectionHeaderTitle == "SẮP TỚI" ? "Chưa có bài sắp tới" : "Ngày mai không có bài!"))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả bài tập đều đã làm xong.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }

    private func singleHeroTaskView(item: Coursework) -> some View {
        let themeColor = SubjectArtHelper.themeColor(for: item.courseName, title: item.title)
        let mainHeadline = item.title.isEmpty ? item.courseName : item.title
        let subHeadline = item.courseName
        let descSnippet: String = {
            if let desc = item.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return desc.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .first(where: { !$0.isEmpty }) ?? ""
            }
            return ""
        }()

        return Link(destination: item.destinationURL) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(themeColor)
                            .frame(width: 26, height: 26)

                        Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text(subHeadline)
                        .font(WidgetFontSystem.courseTitle(size: 12))
                        .foregroundStyle(themeColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 4)

                    if item.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Đã xong")
                                .font(WidgetFontSystem.statusTag(size: 12))
                        }
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                    } else if let deadline = item.widgetDeadlineLabel {
                        HStack(spacing: 3.5) {
                            Image(systemName: "clock")
                                .font(.system(size: 10.5, weight: .semibold))
                            Text(deadline)
                                .font(WidgetFontSystem.statusTag(size: 10.5))
                        }
                        .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : ChunkyTheme.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3.5)
                        .background(item.isUrgent ? ChunkyTheme.urgentAccent.opacity(0.12) : Color.black.opacity(0.06))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }

                Text(mainHeadline)
                    .font(WidgetFontSystem.courseTitle(size: 15))
                    .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if !descSnippet.isEmpty && descSnippet != mainHeadline {
                    Text(descSnippet)
                        .font(WidgetFontSystem.meta(size: 11))
                        .foregroundStyle(ChunkyTheme.textMuted)
                        .lineLimit(1)
                        .lineSpacing(1.5)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: item.isCompleted ? "checkmark" : "exclamationmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                        Text(item.isCompleted ? "Bài tập đã được đánh dấu hoàn thành" : (item.isUrgent ? "Hạn nộp sắp tới, hãy hoàn thành sớm" : "Chạm để xem chi tiết bài tập"))
                            .font(WidgetFontSystem.meta(size: 12))
                    }
                    .foregroundStyle(ChunkyTheme.textMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pureTaskListRows: some View {
        let itemsToShow = Array(displayItems.prefix(3))

        VStack(spacing: 0) {
            ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                Link(destination: item.destinationURL) {
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 7) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                                    .frame(width: 26, height: 26)

                                Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }

                            VStack(alignment: .leading, spacing: 1.5) {
                                let mainHeadline = item.title.isEmpty ? item.courseName : item.title
                                let subHeadline = item.title.isEmpty ? (item.description?.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "") : item.courseName

                                Text(mainHeadline)
                                    .font(WidgetFontSystem.courseTitle(size: displayItems.count <= 2 ? 15.5 : 14))
                                    .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                if !subHeadline.isEmpty {
                                    Text(subHeadline)
                                        .font(WidgetFontSystem.meta(size: displayItems.count <= 2 ? 12 : 11))
                                        .foregroundStyle(ChunkyTheme.textMuted)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)
                                }
                            }

                            Spacer(minLength: 4)

                            if item.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundStyle(Color.green)
                            } else if let deadline = item.widgetDeadlineLabel {
                                Text(deadline)
                                    .font(WidgetFontSystem.statusTag(size: displayItems.count <= 2 ? 11.5 : 10.5))
                                    .lineLimit(1)
                                    .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : ChunkyTheme.textMuted)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2.5)
                                    .background(item.isUrgent ? ChunkyTheme.urgentAccent.opacity(0.12) : Color.black.opacity(0.04))
                                    .clipShape(Capsule())
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .frame(minHeight: 0, maxHeight: .infinity)

                        if index < itemsToShow.count - 1 {
                            Rectangle()
                                .fill(ChunkyTheme.editorialHairline)
                                .frame(height: 0.8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func editorialSubjectBadge(name: String) -> some View {
        let code = SubjectArtHelper.badgeCode(for: name)
        let color = SubjectArtHelper.themeColor(for: name)

        Text(code)
            .font(.system(size: 8.5, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 4.5)
            .padding(.vertical, 1.8)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
    }
}

#Preview("Bốn bài mẫu (Light Mode)") {
    MediumWidgetView(courseworkList: RisoMockData.fourTasks)
        .frame(width: 364, height: 170)
}

#Preview("Một bài Hero") {
    MediumWidgetView(courseworkList: [RisoMockData.physicsTask])
        .frame(width: 364, height: 170)
}

#Preview("Hai bài") {
    MediumWidgetView(courseworkList: [RisoMockData.historyTask, RisoMockData.physicsTask])
        .frame(width: 364, height: 170)
}

#Preview("Empty State (Rảnh rồi)") {
    MediumWidgetView(courseworkList: [])
        .frame(width: 364, height: 170)
}
