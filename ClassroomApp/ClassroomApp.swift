import SwiftUI
#if os(macOS)
import AppKit
import UserNotifications

final class ClassroomAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var backgroundSyncTimer: Timer?
    private var didBecomeActiveObserver: (any NSObjectProtocol)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
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
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
            if let window = sender.windows.first {
                window.makeKeyAndOrderFront(nil)
                return true
            }
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
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
            SidebarCommands()
            CommandGroup(replacing: .appSettings) {
                Button("Cài đặt...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsModal"), object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            CommandGroup(replacing: .newItem) {
                Button("Tạo ghi chú mới...") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewPersonalNote"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Báo bài") {
                Button("Làm mới & Đồng bộ") {
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerSync"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
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
