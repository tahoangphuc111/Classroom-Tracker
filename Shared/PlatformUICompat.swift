import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public extension Color {
    static var platformWindowBackground: Color {
        Color(red: 0.965, green: 0.970, blue: 0.976)
    }

    static var platformControlBackground: Color {
        Color.white
    }

    static var platformSidebarBackground: Color {
        Color(red: 0.948, green: 0.954, blue: 0.962)
    }

    static var platformCardBorder: Color {
        Color.black.opacity(0.06)
    }

    static var platformCardHoverBorder: Color {
        Color.black.opacity(0.12)
    }

    static var platformCardSelectedBorder: Color {
        Color(red: 0.12, green: 0.52, blue: 0.95).opacity(0.45)
    }

    static var platformCardSelectedBackground: Color {
        Color(red: 0.12, green: 0.52, blue: 0.95).opacity(0.06)
    }

    static var platformSubtleFill: Color {
        Color.black.opacity(0.035)
    }

    static var platformDivider: Color {
        Color.black.opacity(0.07)
    }

    static var platformTextPrimary: Color {
        Color(red: 0.11, green: 0.13, blue: 0.18)
    }

    static var platformTextSecondary: Color {
        Color(red: 0.44, green: 0.48, blue: 0.56)
    }

    static var platformTextTertiary: Color {
        Color(red: 0.62, green: 0.66, blue: 0.72)
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
