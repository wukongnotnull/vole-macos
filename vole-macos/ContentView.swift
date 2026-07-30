import SwiftUI

struct ContentView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        CleanRootView(session: session)
    }
}
