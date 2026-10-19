import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
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
        return activeItems
    }

    private var primaryItem: Coursework? {
        displayItems.first
    }

    private var extraCount: Int {
        if activeItems.isEmpty {
            return 0
        }
        let shownCount = displayItems.count == 1 ? 1 : 2
        return max(0, activeItems.count - shownCount)
    }

    private var characterEmotion: EmberEmotion {
        if activeItems.isEmpty {
            return courseworkList.contains(where: \.isCompleted) ? .celebrating : .sleeping
        } else if activeItems.count >= 3 {
            return .stressed
        } else {
            return .normal
        }
    }

    public var body: some View {
        ZStack {
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            if !isLoggedIn {
                loggedOutSmallView
            } else {
                VStack(spacing: 5) {
                    HStack(alignment: .center, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 28))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 1)

                            if activeItems.isEmpty && !courseworkList.isEmpty {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                            } else {
                                Text(sectionHeaderTitle)
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                                    .lineLimit(1)
                            }

                            if extraCount > 0 {
                                Text("+\(extraCount)")
                                    .font(WidgetFontSystem.statusTag(size: 8.5))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 1.5)
                                    .background(ChunkyTheme.urgentAccent)
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer(minLength: 2)

                        ChunkyEmberCharacterView(emotion: characterEmotion, size: 44)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)

                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(ChunkyTheme.sheetBg)
                            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 5, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                            )

                        cardContent
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
            }
        }
        .widgetURL(primaryItem?.destinationURL)
        .unredacted()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loggedOutSmallView: some View {
        VStack(spacing: 6) {
            ChunkyEmberCharacterView(emotion: .normal, size: 44)

            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ChunkyTheme.sheetBg)
                    .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                    )

                VStack(spacing: 3) {
                    Text("Chưa đăng nhập")
                        .font(WidgetFontSystem.courseTitle(size: 10))
                        .foregroundStyle(ChunkyTheme.textPrimary)
                        .lineLimit(1)

                    Text("Chạm để đăng nhập")
                        .font(WidgetFontSystem.meta(size: 8))
                        .foregroundStyle(ChunkyTheme.pillBlue)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var cardContent: some View {
        if displayItems.isEmpty {
            emptyStateView
        } else if displayItems.count == 1, let item = displayItems.first {
            singleItemCard(item: item)
        } else {
            multiItemCard(items: displayItems)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
                Text("Rảnh rồi!")
                    .font(WidgetFontSystem.sectionHeader(size: 13))
                    .tracking(0.0)
                    .foregroundStyle(ChunkyTheme.textPrimary)
            }
            Text("Nghỉ ngơi nhé")
                .font(WidgetFontSystem.meta(size: 10.5))
                .tracking(0.0)
                .foregroundStyle(ChunkyTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func singleItemCard(item: Coursework) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                        .frame(width: 22, height: 22)

                    Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                Text(item.courseName)
                    .font(WidgetFontSystem.courseTitle(size: 12.5))
                    .foregroundStyle(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 2)

                statusTag(for: item, fontSize: 9.5)
            }

            Rectangle()
                .fill(ChunkyTheme.editorialHairline)
                .frame(height: 0.8)

            let headline = item.title.isEmpty ? item.courseName : item.title
            Text(headline)
                .font(WidgetFontSystem.courseTitle(size: 14.5))
                .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .lineSpacing(2)

            Spacer(minLength: 0)

            HStack(spacing: 3.5) {
                Image(systemName: "clock")
                    .font(.system(size: 9, weight: .semibold))
                Text(dueLabel(for: item))
                    .font(WidgetFontSystem.meta(size: 9.5))
            }
            .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : (item.isCompleted ? Color.green : ChunkyTheme.textMuted))
            .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 1)
    }

    private func multiItemCard(items: [Coursework]) -> some View {
        let itemsToShow = Array(items.prefix(2))
        return VStack(spacing: 0) {
            ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, subItem in
                HStack(alignment: .center, spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                            .fill(SubjectArtHelper.themeColor(for: subItem.courseName, title: subItem.title))
                            .frame(width: 21, height: 21)

                        Image(systemName: SubjectArtHelper.icon(for: subItem.courseName, title: subItem.title))
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 1.5) {
                        let headline = subItem.title.isEmpty ? subItem.courseName : subItem.title
                        Text(headline)
                            .font(WidgetFontSystem.courseTitle(size: 12))
                            .foregroundStyle(subItem.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        HStack(spacing: 3) {
                            Text(subItem.courseName)
                                .font(WidgetFontSystem.meta(size: 9.5))
                                .foregroundStyle(ChunkyTheme.textMuted)
                                .lineLimit(1)

                            Text("•")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(ChunkyTheme.textMuted.opacity(0.45))

                            Text(dueLabel(for: subItem))
                                .font(WidgetFontSystem.meta(size: 9.5))
                                .foregroundStyle(subItem.isUrgent ? ChunkyTheme.urgentAccent : (subItem.isCompleted ? Color.green : ChunkyTheme.textMuted))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    if subItem.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                }
                .frame(maxHeight: .infinity)

                if index < itemsToShow.count - 1 {
                    Rectangle()
                        .fill(ChunkyTheme.editorialHairline)
                        .frame(height: 0.8)
                }
            }
        }
    }

    private func dueLabel(for item: Coursework) -> String {
        if item.isCompleted {
            return "Đã nộp"
        } else {
            return item.compactDueString
        }
    }

    @ViewBuilder
    private func statusTag(for item: Coursework, fontSize: CGFloat) -> some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: fontSize + 4, weight: .bold))
                .foregroundStyle(Color.green)
        } else {
            Text(item.compactDueString)
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : ChunkyTheme.textMuted)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(item.isUrgent ? ChunkyTheme.urgentAccent.opacity(0.12) : Color.black.opacity(0.04))
                .clipShape(Capsule())
        }
    }
}
