import SwiftUI

@main
struct ClassroomApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .frame(minWidth: 800, minHeight: 640)
                .onOpenURL { url in
                    print("Nhận URL callback: \(url)")
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
