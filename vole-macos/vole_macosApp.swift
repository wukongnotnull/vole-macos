import SwiftUI

@main
struct vole_macosApp: App {
    @StateObject private var session = CleanSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
    }
}
