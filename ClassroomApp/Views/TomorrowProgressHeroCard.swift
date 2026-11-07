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

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                FloatingEmberView(emotion: emotion, size: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isAllDone ? "Xuất sắc! Đã xong hết" : "Báo bài \(titleSuffix)")
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text(isAllDone ? "Đã hoàn thành toàn bộ bài tập \(titleSuffix)." : "Còn \(incompleteCount) bài tập cần nộp.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                ShareLink(item: shareText) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 11, weight: .bold))
                        Text("Chia sẻ")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.white.opacity(0.22))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 5) {
                HStack {
                    Text(isAllDone ? "Hoàn thành 100%!" : "Tiến độ: \(completedCount)/\(totalCount) bài tập")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))

                    Spacer()

                    Text("\(Int(progressFraction * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.90))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(6, geo.size.width * CGFloat(progressFraction)), height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: progressFraction)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(13)
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
}

public struct TomorrowHeroBanner: View {
    public init() {}

    public var body: some View {
        #if os(macOS)
        let img = NSImage(named: "HeroBaoBai")
        #else
        let img = UIImage(named: "HeroBaoBai")
        #endif
        return Group {
            if img != nil {
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
}
