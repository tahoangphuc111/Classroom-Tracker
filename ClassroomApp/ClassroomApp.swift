import SwiftUI
#if os(macOS)
import AppKit

final class ClassroomAppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundSyncTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        enforceAquaAndWindowConstraints()
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enforceAquaAndWindowConstraints()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            ClassroomStorage.shared.synchronizeAllStorageLayers()
            ClassroomStorage.shared.notifyWidgetReload()
            Task { @MainActor in
                if GoogleOAuthService.shared.isAuthenticated {
                    await ClassroomAPIService.shared.syncAll()
                }
            }
        }

        ClassroomStorage.shared.synchronizeAllStorageLayers()
        ClassroomStorage.shared.notifyWidgetReload()

        Task { @MainActor in
            if GoogleOAuthService.shared.isAuthenticated {
                await ClassroomAPIService.shared.syncAll()
            }
        }

        // Auto-sync every 15 minutes
        backgroundSyncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
            Task { @MainActor in
                if GoogleOAuthService.shared.isAuthenticated {
                    await ClassroomAPIService.shared.syncAll()
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        backgroundSyncTimer?.invalidate()
        backgroundSyncTimer = nil
    }

    private func enforceAquaAndWindowConstraints() {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        for window in NSApplication.shared.windows {
            window.appearance = NSAppearance(named: .aqua)
            window.minSize = NSSize(width: 900, height: 620)
            if window.frame.size.width < 900 || window.frame.size.height < 620 {
                var frame = window.frame
                frame.size.width = max(frame.size.width, 980)
                frame.size.height = max(frame.size.height, 680)
                window.setFrame(frame, display: true, animate: true)
            }
        }
    }
}
#endif

@main
struct ClassroomApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(ClassroomAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 620)
                #endif
                .onOpenURL { url in
                    print("Nhận URL callback: \(url)")
                }
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}
