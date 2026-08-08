import SwiftUI

struct ContentView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        CleanRootView(session: session, helperStatus: helperStatus)
    }
}
