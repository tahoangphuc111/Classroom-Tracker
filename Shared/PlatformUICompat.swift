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

public enum PlatformClipboard {
    public static func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
    }
}

public enum PlatformHaptics {
    public static func trigger() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        #elseif os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
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
