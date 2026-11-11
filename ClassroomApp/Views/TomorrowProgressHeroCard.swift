import SwiftUI

public struct TomorrowProgressHeroCard: View {
    public let totalCount: Int
    public let completedCount: Int
    public let hasTomorrowTasks: Bool
    public let hasTodayTasks: Bool
    public let shareText: String

    public init(
        totalCount: Int,
        completedCount: Int,
        hasTomorrowTasks: Bool,
        hasTodayTasks: Bool,
        shareText: String
    ) {
        self.totalCount = totalCount
        self.completedCount = completedCount
        self.hasTomorrowTasks = hasTomorrowTasks
        self.hasTodayTasks = hasTodayTasks
        self.shareText = shareText
    }

    public var body: some View {
        let incompleteCount = totalCount - completedCount
        let isAllDone = totalCount > 0 && incompleteCount == 0
        let progressFraction = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        let titleSuffix = hasTomorrowTasks ? "ngày mai" : (hasTodayTasks ? "hôm nay" : "sắp tới")

        let emotion: EmberEmotion = {
            if isAllDone { return .celebrating }
            if incompleteCount >= 3 { return .stressed }
            return .normal
        }()

        return VStack(spacing: 11) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    summaryHeading(emotion: emotion, isAllDone: isAllDone, incompleteCount: incompleteCount, titleSuffix: titleSuffix)
                        .frame(minWidth: 220)
                    shareButton
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryHeading(emotion: emotion, isAllDone: isAllDone, incompleteCount: incompleteCount, titleSuffix: titleSuffix)
                    shareButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text(isAllDone ? "Hoàn thành 100%!" : "Tiến độ: \(completedCount)/\(totalCount) bài tập")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .contentTransition(.numericText())

                    Spacer()

                    Text("\(Int(progressFraction * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.90))
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 7.5)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(7.5, geo.size.width * CGFloat(progressFraction)), height: 7.5)
                            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: progressFraction)
                    }
                }
                .frame(height: 7.5)
            }
        }
        .padding(15)
        .scaleEffect(isAllDone ? 1.015 : 1.0)
        .animation(.spring(response: 0.38, dampingFraction: 0.70), value: isAllDone)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(ChunkyTheme.skyGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 3)
        .padding(.bottom, 4)
    }
    private func summaryHeading(emotion: EmberEmotion, isAllDone: Bool, incompleteCount: Int, titleSuffix: String) -> some View {
        HStack(spacing: 12) {
            FloatingEmberView(emotion: emotion, size: 58)

            VStack(alignment: .leading, spacing: 3.5) {
                Text(isAllDone ? "Xuất sắc! Đã xong hết" : "Báo bài \(titleSuffix)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.opacity)

                Text(isAllDone ? "Đã hoàn thành toàn bộ bài tập \(titleSuffix)." : "Còn \(incompleteCount) bài tập cần nộp.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(2)
                    .contentTransition(.numericText())
            }
        }
        .frame(idealWidth: 280, maxWidth: .infinity, alignment: .leading)
    }

    private var shareButton: some View {
        ShareLink(item: shareText) {
            HStack(spacing: 4.5) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .bold))
                Text("Chia sẻ")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white.opacity(0.22))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
            )
        }
        .buttonStyle(SpringPressButtonStyle(scale: 0.94, pressedOpacity: 0.88))
        .fixedSize(horizontal: true, vertical: false)
    }

}

public struct TomorrowHeroBanner: View {
    public init() {}

    private static let hasHeroImageAsset: Bool = {
        #if os(macOS)
        return NSImage(named: "HeroBaoBai") != nil
        #else
        return UIImage(named: "HeroBaoBai") != nil
        #endif
    }()

    private var hasHeroImage: Bool {
        Self.hasHeroImageAsset
    }

    @ViewBuilder
    public var body: some View {
        if hasHeroImage {
            ZStack(alignment: .bottom) {
                Image("HeroBaoBai")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .clipped()

                LinearGradient(
                    colors: [Color.clear, Color.platformWindowBackground.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.platformCardBorder.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(.bottom, 4)
        }
    }
}
