import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public extension Color {
    static var platformWindowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(red: 0.965, green: 0.970, blue: 0.976)
        #endif
    }

    static var platformControlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.white
        #endif
    }

    static var platformSidebarBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(red: 0.948, green: 0.954, blue: 0.962)
        #endif
    }

    static var platformCardBorder: Color {
        Color.primary.opacity(0.08)
    }

    static var platformCardHoverBorder: Color {
        Color.primary.opacity(0.16)
    }

    static var platformCardSelectedBorder: Color {
        Color(red: 0.12, green: 0.52, blue: 0.95).opacity(0.6)
    }

    static var platformCardSelectedBackground: Color {
        #if os(macOS)
        Color(nsColor: .selectedContentBackgroundColor).opacity(0.12)
        #elseif os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color.white
        #endif
    }

    static var platformSubtleFill: Color {
        Color.primary.opacity(0.04)
    }

    static var platformDivider: Color {
        Color.primary.opacity(0.10)
    }

    static var platformTextPrimary: Color {
        Color.primary
    }

    static var platformTextSecondary: Color {
        Color.secondary
    }

    static var platformTextTertiary: Color {
        Color.secondary.opacity(0.7)
    }
}

public enum AppleOSDetector {
    public static var isAppleOS: Bool {
        #if os(macOS) || os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Determines whether the runtime OS and compiler support Apple Liquid Glass (`glassEffect` & `GlassEffectContainer`).
    /// In Swift availability, `macOS 26.0, *` acts as the minimum floor and covers macOS 26.x, macOS 27.x, and future releases.
    public static var supportsLiquidGlass: Bool {
        #if (os(macOS) || os(iOS)) && compiler(>=6.4)
        if #available(iOS 26.0, macOS 26.0, *) {
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

public enum PlatformClipboard {
    public static func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif os(iOS)
        if Thread.isMainThread {
            UIPasteboard.general.string = text
        } else {
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
            }
        }
        #endif
    }
}

public enum PlatformHaptics {
    public enum FeedbackStyle {
        case light
        case medium
        case heavy
        case selection
        case success
        case warning
        case error
    }

    public static func trigger(_ style: FeedbackStyle = .medium) {
        #if os(macOS)
        switch style {
        case .error, .warning:
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        default:
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
        #elseif os(iOS)
        let action = {
            switch style {
            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            case .selection:
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
        #endif
    }
}

public enum PlatformURLOpener {
    @MainActor
    public static func open(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        let applicationSelector = NSSelectorFromString("sharedApplication")
        if UIApplication.responds(to: applicationSelector),
           let app = UIApplication.perform(applicationSelector)?.takeUnretainedValue() as? UIApplication {
            app.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}
