import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
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

    private var sectionCapsuleLabel: String {
        switch sectionHeaderTitle {
        case "HÔM NAY & MAI": return "Hôm nay & mai"
        case "HÔM NAY": return "Hôm nay"
        case "QUÁ HẠN": return "Quá hạn"
        case "SẮP TỚI": return "Sắp tới"
        default: return "Ngày mai"
        }
    }

    private var activeItems: [Coursework] {
        courseworkList.filter { !$0.isCompleted }
    }

    private var allItems: [Coursework] {
        courseworkList
    }

    private var completedItems: [Coursework] {
        allItems.filter(\.isCompleted)
    }

    private var characterEmotion: EmberEmotion {
        if activeItems.isEmpty {
            return !completedItems.isEmpty ? .celebrating : .sleeping
        } else if activeItems.count >= 4 {
            return .stressed
        } else {
            return .normal
        }
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            backgroundClouds

            if !isLoggedIn {
                loggedOutLargeView
                    .widgetURL(URL(string: "classroomwidget://login"))
            } else {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 14) {
                        ChunkyEmberCharacterView(emotion: characterEmotion, size: 78)
                            .padding(.leading, 18)

                        VStack(alignment: .leading, spacing: 4.5) {
                            HStack(alignment: .firstTextBaseline, spacing: 7) {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.counter(size: 44))
                                    .foregroundStyle(Color.white)
                                    .shadow(color: Color.black.opacity(0.14), radius: 0, x: 0, y: 1.5)

                                Text(activeItems.count == 0 ? "HOÀN TẤT" : "CẦN NỘP")
                                    .font(WidgetFontSystem.sectionHeader(size: 17))
                                    .tracking(0.0)
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                            }

                            HStack(spacing: 6) {
                                summaryCapsule(label: "\(sectionCapsuleLabel): \(activeItems.count)", isUrgent: activeItems.contains(where: \.isUrgent))
                                if !completedItems.isEmpty {
                                    summaryCapsule(label: "Đã xong: \(completedItems.count)", isUrgent: false, isSuccess: true)
                                }
                            }
                        }

                        Spacer()
                    }
                    .frame(height: 90)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            Text(sectionHeaderTitle)
                                .font(WidgetFontSystem.sectionHeader(size: 12))
                                .tracking(0.0)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer()

                            if !activeItems.isEmpty {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.sectionHeader(size: 11))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 7.5)
                                    .padding(.vertical, 2)
                                    .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 13)
                        .padding(.bottom, 6)

                        Rectangle()
                            .fill(ChunkyTheme.editorialHairline)
                            .frame(height: 0.8)
                            .padding(.horizontal, 16)

                        if allItems.isEmpty {
                            emptyStateView
                        } else if allItems.count == 1, let singleItem = allItems.first {
                            singleHeroLargeView(item: singleItem)
                        } else {
                            let itemsToShow = Array(allItems.prefix(4))
                            let count = itemsToShow.count

                            let badgeSize: CGFloat = {
                                switch count {
                                case 2: return 44
                                case 3: return 38
                                default: return 34
                                }
                            }()

                            let iconSize: CGFloat = {
                                switch count {
                                case 2: return 22
                                case 3: return 19
                                default: return 16
                                }
                            }()

                            let titleFontSize: CGFloat = {
                                switch count {
                                case 2: return 19
                                case 3: return 17
                                default: return 15.5
                                }
                            }()

                            let tagFontSize: CGFloat = {
                                switch count {
                                case 2: return 13
                                case 3: return 12
                                default: return 11.5
                                }
                            }()

                            VStack(spacing: 0) {
                                ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                                    Link(destination: item.destinationURL) {
                                        VStack(spacing: 0) {
                                            HStack(alignment: .center, spacing: 14) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: count <= 2 ? 11 : 9, style: .continuous)
                                                        .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                                                        .frame(width: badgeSize, height: badgeSize)

                                                    Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                                                        .font(.system(size: iconSize, weight: .bold))
                                                        .foregroundStyle(Color.white)
                                                }

                                                VStack(alignment: .leading, spacing: 2) {
                                                    let mainHeadline = item.title.isEmpty ? item.courseName : item.title
                                                    let subHeadline = item.title.isEmpty ? (item.description?.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "") : item.courseName

                                                    Text(mainHeadline)
                                                        .font(WidgetFontSystem.courseTitle(size: titleFontSize))
                                                        .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.85)

                                                    if !subHeadline.isEmpty {
                                                        Text(subHeadline)
                                                            .font(WidgetFontSystem.meta(size: max(11, titleFontSize - 3.0)))
                                                            .foregroundStyle(ChunkyTheme.textMuted)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.85)
                                                    }
                                                }

                                                Spacer(minLength: 4)

                                                statusTag(for: item, fontSize: tagFontSize)
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
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(ChunkyTheme.sheetBg)
                            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 8, x: 0, y: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .unredacted()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loggedOutLargeView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                ChunkyEmberCharacterView(emotion: .normal, size: 78)
                    .padding(.leading, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("BÁO BÀI NGÀY MAI")
                        .font(WidgetFontSystem.sectionHeader(size: 14))
                        .foregroundStyle(ChunkyTheme.butterYellow)

                    Text("Chưa đăng nhập")
                        .font(WidgetFontSystem.counter(size: 26))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.14), radius: 0, x: 0, y: 1.5)
                }

                Spacer()
            }
            .frame(height: 90)

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(ChunkyTheme.pillBlue)

                VStack(spacing: 5) {
                    Text("Chạm để đăng nhập")
                        .font(WidgetFontSystem.courseTitle(size: 17))
                        .foregroundStyle(ChunkyTheme.textPrimary)

                    Text("Đăng nhập tài khoản Google Classroom để theo dõi bài tập cần hoàn thành cho ngày mai.")
                        .font(WidgetFontSystem.meta(size: 13))
                        .foregroundStyle(ChunkyTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 20)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChunkyTheme.sheetBg)
                    .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 8, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var backgroundClouds: some View {
        Canvas { context, size in
            let cloud1 = CGRect(x: size.width - 95, y: 12, width: 80, height: 20)
            context.fill(Path(roundedRect: cloud1, cornerRadius: 10), with: .color(Color.white.opacity(0.18)))

            let cloud2 = CGRect(x: size.width - 150, y: 22, width: 55, height: 16)
            context.fill(Path(roundedRect: cloud2, cornerRadius: 8), with: .color(Color.white.opacity(0.14)))
        }
        .allowsHitTesting(false)
    }

    private func singleHeroLargeView(item: Coursework) -> some View {
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(themeColor)
                            .frame(width: 38, height: 38)

                        Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(subHeadline)
                            .font(WidgetFontSystem.courseTitle(size: 15))
                            .foregroundStyle(themeColor)
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 11, weight: .semibold))
                            Text(item.dayAndTimeString)
                                .font(WidgetFontSystem.meta(size: 12.5))
                        }
                        .foregroundStyle(ChunkyTheme.textMuted)
                    }

                    Spacer(minLength: 6)

                    statusTag(for: item, fontSize: 13.5)
                }

                Rectangle()
                    .fill(ChunkyTheme.editorialHairline)
                    .frame(height: 0.8)

                Text(mainHeadline)
                    .font(WidgetFontSystem.courseTitle(size: 18))
                    .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                    .lineLimit(3)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.85)

                if !descSnippet.isEmpty && descSnippet != mainHeadline {
                    Text(descSnippet)
                        .font(WidgetFontSystem.meta(size: 12))
                        .foregroundStyle(ChunkyTheme.textMuted)
                        .lineLimit(2)
                        .lineSpacing(2.5)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(item.isCompleted ? "Bài tập đã được đánh dấu hoàn thành" : "Chạm để xem chi tiết bài tập và nộp bài")
                            .font(WidgetFontSystem.meta(size: 14))
                    }
                    .foregroundStyle(ChunkyTheme.textMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
                Text("Ngày mai không có bài!")
                    .font(WidgetFontSystem.sectionHeader(size: 22))
                    .tracking(0.0)
                    .foregroundStyle(ChunkyTheme.textPrimary)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
            }
            Text("Tất cả bài tập đều đã làm xong.")
                .font(WidgetFontSystem.meta(size: 14.5))
                .tracking(0.0)
                .foregroundStyle(ChunkyTheme.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func statusTag(for item: Coursework, fontSize: CGFloat) -> some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: fontSize + 5, weight: .bold))
                .foregroundStyle(Color.green)
        } else {
            Text(item.compactDueString)
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : ChunkyTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.isUrgent ? ChunkyTheme.urgentAccent.opacity(0.12) : Color.black.opacity(0.04))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func summaryCapsule(label: String, isUrgent: Bool, isSuccess: Bool = false) -> some View {
        HStack(spacing: 4) {
            if isSuccess {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
            }
            Text(label)
                .font(WidgetFontSystem.meta(size: 10.5))
                .tracking(0.0)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(isUrgent ? ChunkyTheme.urgentAccent : (isSuccess ? Color(red: 0.16, green: 0.72, blue: 0.44).opacity(0.85) : Color.white.opacity(0.24)))
        .clipShape(Capsule())
    }
}
