import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
    let courseworkList: [Coursework]

    public init(courseworkList: [Coursework]) {
        self.courseworkList = courseworkList
    }

    private var tomorrowItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow && !$0.isCompleted }
    }

    private var primaryItem: Coursework? {
        tomorrowItems.first
    }

    private var extraCount: Int {
        max(0, tomorrowItems.count - 1)
    }

    private var characterEmotion: EmberEmotion {
        if tomorrowItems.isEmpty {
            return courseworkList.contains(where: \.isCompleted) ? .celebrating : .sleeping
        } else if tomorrowItems.count >= 3 {
            return .stressed
        } else {
            return .normal
        }
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ChunkyTheme.sheetBg)
                        .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text("NGÀY MAI")
                                .font(WidgetFontSystem.sectionHeader(size: 8))
                                .tracking(0.8)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer()

                            if extraCount > 0 {
                                Text("+\(extraCount)")
                                    .font(WidgetFontSystem.statusTag(size: 8))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        Rectangle()
                            .fill(ChunkyTheme.editorialHairline)
                            .frame(height: 0.8)

                        if let item = primaryItem {
                            if extraCount == 0 {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(alignment: .center, spacing: 7) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(SubjectArtHelper.themeColor(for: item.courseName))
                                                .frame(width: 22, height: 22)

                                            Image(systemName: SubjectArtHelper.icon(for: item.courseName))
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(Color.white)
                                        }

                                        Text(item.courseName)
                                            .font(WidgetFontSystem.courseTitle(size: 13.5))
                                            .foregroundStyle(ChunkyTheme.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }

                                    Text(item.timeOnlyString)
                                        .font(WidgetFontSystem.statusTag(size: 7.5))
                                        .foregroundStyle(ChunkyTheme.textMuted)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(Color.black.opacity(0.04))
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 3)
                            } else {
                                let itemsToShow = Array(tomorrowItems.prefix(2))
                                VStack(spacing: 5) {
                                    ForEach(itemsToShow, id: \.id) { subItem in
                                        HStack(spacing: 7) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .fill(SubjectArtHelper.themeColor(for: subItem.courseName))
                                                    .frame(width: 19, height: 19)

                                                Image(systemName: SubjectArtHelper.icon(for: subItem.courseName))
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .foregroundStyle(Color.white)
                                            }

                                            Text(subItem.courseName)
                                                .font(WidgetFontSystem.courseTitle(size: 12))
                                                .foregroundStyle(ChunkyTheme.textPrimary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)

                                            Spacer(minLength: 0)

                                            Text(subItem.timeOnlyString)
                                                .font(WidgetFontSystem.meta(size: 7.5))
                                                .foregroundStyle(ChunkyTheme.textMuted)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        } else {
                            VStack(spacing: 2) {
                                Spacer()
                                Text("✦ Rảnh rồi!")
                                    .font(WidgetFontSystem.sectionHeader(size: 11.5))
                                    .foregroundStyle(ChunkyTheme.textPrimary)
                                Text("Nghỉ ngơi nhé")
                                    .font(WidgetFontSystem.meta(size: 9))
                                    .foregroundStyle(ChunkyTheme.textMuted)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(8.5)
                }
                .padding(.horizontal, 9)
                .padding(.top, 9)
                .frame(height: 98)

                Spacer(minLength: 0)
            }

            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(tomorrowItems.count)")
                        .font(WidgetFontSystem.counter(size: 18))
                        .foregroundStyle(Color.white)
                    Text("CẦN NỘP")
                        .font(WidgetFontSystem.sectionHeader(size: 8))
                        .tracking(0.6)
                        .foregroundStyle(ChunkyTheme.butterYellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.black.opacity(0.18))
                .clipShape(Capsule())
                .padding(.leading, 11)
                .padding(.bottom, 8)

                Spacer()

                ChunkyEmberCharacterView(emotion: characterEmotion, size: 48)
                    .padding(.trailing, 10)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
    }
}
