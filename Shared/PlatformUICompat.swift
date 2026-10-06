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
        return Color(NSColor.windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.systemBackground)
        #endif
    }

    static var platformControlBackground: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(.secondarySystemBackground)
        #endif
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
