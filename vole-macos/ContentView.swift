import SwiftUI

struct ContentView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        ShellView(session: session, helperStatus: helperStatus)
    }
}
