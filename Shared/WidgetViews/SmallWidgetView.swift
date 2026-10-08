import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
    let courseworkList: [Coursework]

    public init(courseworkList: [Coursework]) {
        self.courseworkList = courseworkList
    }

    private var sectionHeaderTitle: String {
        let pending = courseworkList.filter { !$0.isCompleted }
        let hasOverdue = pending.contains(where: \.isOverdue)
        let hasToday = pending.contains(where: \.isDueToday)
        let hasTomorrow = pending.contains(where: \.isDueTomorrow)

        if hasOverdue && !hasToday && !hasTomorrow {
            return "QUÁ HẠN"
        } else if hasToday && hasTomorrow {
            return "HÔM NAY & MAI"
        } else if hasToday {
            return "HÔM NAY"
        } else if hasTomorrow {
            return "NGÀY MAI"
        } else if hasOverdue {
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

            VStack(spacing: 5) {
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 25))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.14), radius: 0, x: 0, y: 1)

                            Text(activeItems.isEmpty && !courseworkList.isEmpty ? "HOÀN TẤT" : "CẦN NỘP")
                                .font(WidgetFontSystem.sectionHeader(size: 8.5))
                                .tracking(0.0)
                                .foregroundStyle(ChunkyTheme.butterYellow)
                        }

                        HStack(spacing: 4) {
                            Text(sectionHeaderTitle)
                                .font(WidgetFontSystem.meta(size: 7.5))
                                .tracking(0.0)
                                .foregroundStyle(Color.white.opacity(0.95))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.22))
                                .clipShape(Capsule())

                            if extraCount > 0 {
                                Text("+\(extraCount)")
                                    .font(WidgetFontSystem.statusTag(size: 7.5))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 2)
                                    .background(ChunkyTheme.urgentAccent)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer(minLength: 2)

                    ChunkyEmberCharacterView(emotion: characterEmotion, size: 42)
                }
                .padding(.horizontal, 10)
                .padding(.top, 7)

                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ChunkyTheme.sheetBg)
                        .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                        )

                    cardContent
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .widgetURL(primaryItem?.destinationURL)
        .unredacted()
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
            Text("✦ Rảnh rồi!")
                .font(WidgetFontSystem.sectionHeader(size: 11.5))
                .tracking(0.0)
                .foregroundStyle(ChunkyTheme.textPrimary)
            Text("Nghỉ ngơi nhé")
                .font(WidgetFontSystem.meta(size: 9))
                .tracking(0.0)
                .foregroundStyle(ChunkyTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func singleItemCard(item: Coursework) -> some View {
        VStack(alignment: .leading, spacing: 3.5) {
            HStack(alignment: .center, spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                        .frame(width: 18, height: 18)

                    Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                Text(item.courseName)
                    .font(WidgetFontSystem.courseTitle(size: 9.5))
                    .foregroundStyle(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 2)

                statusTag(for: item, fontSize: 7.5)
            }

            Rectangle()
                .fill(ChunkyTheme.editorialHairline)
                .frame(height: 0.8)

            let headline = item.title.isEmpty ? item.courseName : item.title
            Text(headline)
                .font(WidgetFontSystem.courseTitle(size: 11))
                .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .lineSpacing(1.5)

            Spacer(minLength: 0)
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
                            .frame(width: 18, height: 18)

                        Image(systemName: SubjectArtHelper.icon(for: subItem.courseName, title: subItem.title))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 1.5) {
                        let headline = subItem.title.isEmpty ? subItem.courseName : subItem.title
                        Text(headline)
                            .font(WidgetFontSystem.courseTitle(size: 9.8))
                            .foregroundStyle(subItem.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        HStack(spacing: 3) {
                            Text(subItem.courseName)
                                .font(WidgetFontSystem.meta(size: 7.8))
                                .foregroundStyle(ChunkyTheme.textMuted)
                                .lineLimit(1)

                            Text("•")
                                .font(.system(size: 6.5, weight: .bold))
                                .foregroundStyle(ChunkyTheme.textMuted.opacity(0.45))

                            Text(dueLabel(for: subItem))
                                .font(WidgetFontSystem.meta(size: 7.8))
                                .foregroundStyle(subItem.isOverdue ? ChunkyTheme.urgentAccent : (subItem.isCompleted ? Color.green : ChunkyTheme.textMuted))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    if subItem.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.green)
                    } else if subItem.isOverdue {
                        Circle()
                            .fill(ChunkyTheme.urgentAccent)
                            .frame(width: 5, height: 5)
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
        } else if item.isOverdue {
            return "Quá hạn"
        } else if item.isDueToday {
            return item.timeOnlyString == "Cuối ngày" ? "23:59" : item.timeOnlyString
        } else if item.isDueTomorrow {
            return item.timeOnlyString == "Cuối ngày" ? "Mai" : "Mai \(item.timeOnlyString)"
        } else if item.dueDate == nil {
            return "Không hạn"
        } else {
            return item.timeOnlyString
        }
    }

    @ViewBuilder
    private func statusTag(for item: Coursework, fontSize: CGFloat) -> some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: fontSize + 4, weight: .bold))
                .foregroundStyle(Color.green)
        } else if item.isOverdue {
            Text("Quá hạn")
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(ChunkyTheme.urgentAccent)
                .clipShape(Capsule())
        } else {
            let labelText = item.timeOnlyString == "Cuối ngày" ? "23:59" : item.timeOnlyString
            Text(labelText)
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(ChunkyTheme.textMuted)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Color.black.opacity(0.04))
                .clipShape(Capsule())
        }
    }
}
