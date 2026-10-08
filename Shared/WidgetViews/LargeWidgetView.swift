import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
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

    private var sectionCapsuleLabel: String {
        switch sectionHeaderTitle {
        case "QUÁ HẠN": return "Quá hạn"
        case "HÔM NAY & MAI": return "Hôm nay & mai"
        case "HÔM NAY": return "Hôm nay"
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

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    ChunkyEmberCharacterView(emotion: characterEmotion, size: 78)
                        .padding(.leading, 18)

                    VStack(alignment: .leading, spacing: 4.5) {
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 40))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.14), radius: 0, x: 0, y: 1.5)

                            Text(activeItems.count == 0 ? "HOÀN TẤT" : "CẦN NỘP")
                                .font(WidgetFontSystem.sectionHeader(size: 15))
                                .tracking(0.0)
                                .foregroundStyle(ChunkyTheme.butterYellow)
                        }

                        HStack(spacing: 6) {
                            summaryCapsule(label: "\(sectionCapsuleLabel): \(activeItems.count)", isUrgent: false)
                            if !completedItems.isEmpty {
                                summaryCapsule(label: "Đã xong: \(completedItems.count)", isUrgent: false, isSuccess: true)
                            }
                        }
                    }

                    Spacer()
                }
                .frame(height: 90)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ChunkyTheme.sheetBg)
                        .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 8, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            Text(sectionHeaderTitle)
                                .font(WidgetFontSystem.sectionHeader(size: 10.5))
                                .tracking(0.0)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer()

                            if !activeItems.isEmpty {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.sectionHeader(size: 10))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 7)
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
                        } else {
                            let itemsToShow = Array(allItems.prefix(5))
                            let count = itemsToShow.count

                            let rowHeight: CGFloat = {
                                switch count {
                                case 1, 2: return 66
                                case 3: return 56
                                case 4: return 48
                                default: return 40
                                }
                            }()

                            let badgeSize: CGFloat = {
                                switch count {
                                case 1, 2: return 44
                                case 3: return 40
                                case 4: return 36
                                default: return 30
                                }
                            }()

                            let iconSize: CGFloat = {
                                switch count {
                                case 1, 2: return 21
                                case 3: return 19
                                case 4: return 17
                                default: return 14
                                }
                            }()

                            let titleFontSize: CGFloat = {
                                switch count {
                                case 1, 2: return 15.5
                                case 3: return 14
                                case 4: return 13
                                default: return 12
                                }
                            }()

                            let tagFontSize: CGFloat = {
                                switch count {
                                case 1, 2: return 10
                                case 3: return 9.5
                                case 4: return 9
                                default: return 8.5
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
                                                            .font(WidgetFontSystem.meta(size: max(9.5, titleFontSize - 3.5)))
                                                            .foregroundStyle(ChunkyTheme.textMuted)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.85)
                                                    }
                                                }

                                                Spacer(minLength: 4)

                                                statusTag(for: item, fontSize: tagFontSize)
                                            }
                                            .frame(height: rowHeight)

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

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .unredacted()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("✦ Tuyệt vời! ✦")
                .font(WidgetFontSystem.sectionHeader(size: 20))
                .tracking(0.0)
                .foregroundStyle(ChunkyTheme.textPrimary)
            Text("Không có môn nào cần nộp")
                .font(WidgetFontSystem.meta(size: 13))
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
        } else if item.isOverdue {
            Text("Quá hạn")
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(ChunkyTheme.urgentAccent)
                .clipShape(Capsule())
        } else {
            Text(item.timeOnlyString)
                .font(WidgetFontSystem.statusTag(size: fontSize))
                .foregroundStyle(ChunkyTheme.textMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(Color.black.opacity(0.04))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func summaryCapsule(label: String, isUrgent: Bool, isSuccess: Bool = false) -> some View {
        HStack(spacing: 3.5) {
            if isSuccess {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
            }
            Text(label)
                .font(WidgetFontSystem.meta(size: 9))
                .tracking(0.0)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(isUrgent ? ChunkyTheme.urgentAccent : (isSuccess ? Color(red: 0.16, green: 0.72, blue: 0.44).opacity(0.85) : Color.white.opacity(0.24)))
        .clipShape(Capsule())
    }
}
