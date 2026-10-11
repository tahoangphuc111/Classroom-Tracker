import SwiftUI
#if os(macOS)
import AppKit

final class ClassroomAppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundSyncTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
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

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
        }
        return true
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
                .frame(minWidth: 840, minHeight: 580)
                #endif
                .onOpenURL { url in
                    #if os(macOS)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    for window in NSApplication.shared.windows {
                        if window.canBecomeKey {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    #endif
                    Task { @MainActor in
                        _ = await GoogleOAuthService.shared.handleIncomingURL(url)
                    }
                }
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Kiểm tra bản cập nhật...") {
                    Task { @MainActor in
                        await AppUpdateService.shared.checkForUpdates(isUserInitiated: true)
                    }
                }
            }
        }
        #endif
    }
}
