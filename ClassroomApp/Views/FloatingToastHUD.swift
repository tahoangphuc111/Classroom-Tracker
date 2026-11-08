import SwiftUI

public struct ToastMessage: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let tint: Color
    public var actionTitle: String? = nil
    public var action: (() -> Void)? = nil

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String = "info.circle.fill",
        tint: Color = .blue,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.actionTitle = actionTitle
        self.action = action
    }

    public static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct FloatingToastHUD: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(toast.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                if let sub = toast.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.platformTextSecondary)
                        .lineLimit(2)
                }
            }

            if let actionTitle = toast.actionTitle, let action = toast.action {
                Button(actionTitle) {
                    PlatformHaptics.trigger()
                    action()
                    onDismiss()
                }
                .buttonStyle(SpringPressButtonStyle(scale: 0.94, pressedOpacity: 0.88))
                .controlSize(.mini)
                .tint(toast.tint)
                .font(.system(size: 11, weight: .semibold))
            }

            Button {
                PlatformHaptics.trigger()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color.platformTextTertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SpringPressButtonStyle(scale: 0.90, pressedOpacity: 0.82))
            .padding(.leading, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 380)
        .appleLiquidGlassSurface(
            style: .regular,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        ) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toast.tint.opacity(0.35), lineWidth: 1)
        )
    }
}
