import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public enum AppleOSDetector {
    public static var isAppleOS: Bool {
        #if os(macOS) || os(iOS)
        return true
        #else
        return false
        #endif
    }

    public static var supportsLiquidGlass: Bool {
        #if os(macOS) || os(iOS)
        if #available(iOS 26.0, macOS 27.0, *) {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    public static var isAppleOS27OrNewer: Bool {
        #if os(macOS) || os(iOS)
        if #available(iOS 27.0, macOS 27.0, *) {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    public static var currentOSDescription: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(macOS)
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #elseif os(iOS)
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "Non-Apple OS"
        #endif
    }

    public static var designEngineStatus: String {
        if supportsLiquidGlass {
            return "Apple Liquid Glass SDK"
        } else if isAppleOS {
            return "Apple OS Material Fallback"
        } else {
            return "Standard Daylight Palette"
        }
    }
}

public enum AppleLiquidGlassStyle: Sendable, Equatable {
    case regular
    case clear
    case tint(Color)
    case interactive
    case interactiveTint(Color)
}

public extension View {
    @ViewBuilder
    func appleLiquidGlassSurface<S: Shape, Fallback: View>(
        style: AppleLiquidGlassStyle = .regular,
        in shape: S,
        isEnabled: Bool = true,
        @ViewBuilder fallback: () -> Fallback
    ) -> some View {
        #if os(macOS) || os(iOS)
        if isEnabled && AppleOSDetector.supportsLiquidGlass {
            if #available(iOS 26.0, macOS 27.0, *) {
                switch style {
                case .regular:
                    self.glassEffect(.regular, in: shape)
                case .clear:
                    self.glassEffect(.clear, in: shape)
                case .tint(let color):
                    self.glassEffect(.regular.tint(color), in: shape)
                case .interactive:
                    self.glassEffect(.regular.interactive(), in: shape)
                case .interactiveTint(let color):
                    self.glassEffect(.regular.tint(color).interactive(), in: shape)
                }
            } else {
                self.background(fallback())
            }
        } else {
            self.background(fallback())
        }
        #else
        self.background(fallback())
        #endif
    }

    @ViewBuilder
    func appleLiquidGlass<S: Shape>(
        style: AppleLiquidGlassStyle = .regular,
        in shape: S,
        fallbackMaterial: Material = .ultraThinMaterial,
        isEnabled: Bool = true
    ) -> some View {
        appleLiquidGlassSurface(style: style, in: shape, isEnabled: isEnabled) {
            shape.fill(fallbackMaterial)
        }
    }

    @ViewBuilder
    func appleLiquidGlassCard(
        style: AppleLiquidGlassStyle = .regular,
        cornerRadius: CGFloat = 10,
        isSelected: Bool = false,
        selectedTint: Color = Color.blue,
        isEnabled: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let resolvedStyle: AppleLiquidGlassStyle = {
            if isSelected {
                return .interactiveTint(selectedTint.opacity(0.18))
            } else {
                return style
            }
        }()

        appleLiquidGlassSurface(style: resolvedStyle, in: shape, isEnabled: isEnabled) {
            #if os(macOS)
            shape.fill(isSelected ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12) : Color(nsColor: .controlBackgroundColor))
            #elseif os(iOS)
            shape.fill(isSelected ? Color(uiColor: .secondarySystemBackground) : Color(uiColor: .secondarySystemGroupedBackground))
            #else
            shape.fill(Color.white)
            #endif
        }
    }

    @ViewBuilder
    func appleLiquidGlassPill(
        style: AppleLiquidGlassStyle = .interactive,
        isSelected: Bool = false,
        selectedTint: Color = Color.blue,
        isEnabled: Bool = true
    ) -> some View {
        let resolvedStyle: AppleLiquidGlassStyle = {
            if isSelected {
                return .interactiveTint(selectedTint.opacity(0.85))
            } else {
                return style
            }
        }()

        appleLiquidGlassSurface(style: resolvedStyle, in: Capsule(), isEnabled: isEnabled) {
            #if os(macOS)
            Capsule().fill(isSelected ? selectedTint : Color(nsColor: .controlBackgroundColor))
            #elseif os(iOS)
            Capsule().fill(isSelected ? selectedTint : Color(uiColor: .secondarySystemGroupedBackground))
            #else
            Capsule().fill(isSelected ? selectedTint : Color.white)
            #endif
        }
    }
}

public struct AdaptiveGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    @ViewBuilder private let content: () -> Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        #if os(macOS) || os(iOS)
        if AppleOSDetector.supportsLiquidGlass {
            if #available(iOS 26.0, macOS 27.0, *) {
                if let spacing = spacing {
                    GlassEffectContainer(spacing: spacing) {
                        content()
                    }
                } else {
                    GlassEffectContainer {
                        content()
                    }
                }
            } else {
                content()
            }
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}
