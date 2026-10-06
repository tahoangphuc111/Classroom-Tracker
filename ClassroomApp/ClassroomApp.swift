import SwiftUI

@main
struct ClassroomApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 640)
                #endif
                .onOpenURL { url in
                    print("Nhận URL callback: \(url)")
                }
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}
