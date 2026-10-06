import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
    let courseworkList: [Coursework]

    public init(courseworkList: [Coursework]) {
        self.courseworkList = courseworkList
    }

    private var tomorrowItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow && !$0.isCompleted }
    }

    private var activeItems: [Coursework] {
        tomorrowItems
    }

    private var allItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow }
    }

    private var completedItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow && $0.isCompleted }
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
            // Serene Morning Sky Gradient
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // TOP BANNER: Mascot & Executive Summary (Enhanced typography & presence)
                HStack(alignment: .center, spacing: 14) {
                    ChunkyEmberCharacterView(emotion: characterEmotion, size: 82)
                        .padding(.leading, 18)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 44))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 1.5)

                            Text(activeItems.count == 0 ? "HOÀN TẤT" : "CẦN NỘP")
                                .font(WidgetFontSystem.sectionHeader(size: 16.5))
                                .tracking(1.0)
                                .foregroundStyle(ChunkyTheme.butterYellow)
                        }

                        // Compact Pills with larger font
                        HStack(spacing: 6) {
                            summaryCapsule(label: "Ngày mai: \(activeItems.count)", isUrgent: false)
                            if !completedItems.isEmpty {
                                summaryCapsule(label: "Đã xong: \(completedItems.count)", isUrgent: false, isSuccess: true)
                            }
                        }
                    }

                    Spacer()
                }
                .frame(height: 94)

                // BOTTOM SHEET: Pure Subjects List (Big readable typography)
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
                        // Header with clearer font
                        HStack(alignment: .center) {
                            Text("NGÀY MAI")
                                .font(WidgetFontSystem.sectionHeader(size: 11))
                                .tracking(1.1)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer()

                            if !activeItems.isEmpty {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.sectionHeader(size: 10.5))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 7)

                        Rectangle()
                            .fill(ChunkyTheme.editorialHairline)
                            .frame(height: 0.8)
                            .padding(.horizontal, 16)

                        if allItems.isEmpty {
                            emptyStateView
                        } else {
                            let itemsToShow = Array(allItems.prefix(5))
                            let count = itemsToShow.count

                            // Adaptive row heights & generous typography
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

                            // BIGGER FONTS (TĂNG KÍCH THƯỚC CHỮ)
                            let titleFontSize: CGFloat = {
                                switch count {
                                case 1, 2: return 22
                                case 3: return 20
                                case 4: return 18.5
                                default: return 16
                                }
                            }()

                            let tagFontSize: CGFloat = {
                                switch count {
                                case 1, 2: return 10.5
                                case 3: return 10
                                case 4: return 9.5
                                default: return 8.5
                                }
                            }()

                            VStack(spacing: 0) {
                                ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                                    Link(destination: URL(string: item.alternateLink ?? "https://classroom.google.com")!) {
                                        VStack(spacing: 0) {
                                            HStack(alignment: .center, spacing: 14) {
                                                // Subject Icon Badge
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: count <= 2 ? 11 : 9, style: .continuous)
                                                        .fill(SubjectArtHelper.themeColor(for: item.courseName))
                                                        .frame(width: badgeSize, height: badgeSize)

                                                    Image(systemName: SubjectArtHelper.icon(for: item.courseName))
                                                        .font(.system(size: iconSize, weight: .bold))
                                                        .foregroundStyle(Color.white)
                                                }

                                                 // Course Name with Be Vietnam Pro
                                                Text(item.courseName)
                                                    .font(WidgetFontSystem.courseTitle(size: titleFontSize))
                                                    .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                                                    .lineLimit(1)

                                                Spacer(minLength: 4)

                                                // Status Badge
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("✦ Tuyệt vời! ✦")
                .font(WidgetFontSystem.sectionHeader(size: 20))
                .foregroundStyle(ChunkyTheme.textPrimary)
            Text("Không có môn nào cần nộp")
                .font(WidgetFontSystem.meta(size: 13))
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
        Text(label)
            .font(WidgetFontSystem.meta(size: 9.5))
            .foregroundStyle(isUrgent ? Color.white : (isSuccess ? Color(red: 0.20, green: 0.95, blue: 0.60) : Color.white.opacity(0.92)))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(isUrgent ? ChunkyTheme.urgentAccent : Color.black.opacity(0.18))
            .clipShape(Capsule())
    }
}
