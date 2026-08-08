import SwiftUI

@main
struct vole_macosApp: App {
    @StateObject private var session = CleanSession()
    @StateObject private var helperStatus = HelperStatusModel()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session, helperStatus: helperStatus)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
