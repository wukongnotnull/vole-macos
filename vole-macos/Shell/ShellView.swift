import SwiftUI

struct ShellView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var selection: ShellModule = .clean

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .frame(minWidth: 188)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch selection {
                case .clean:
                    CleanRootView(session: session, helperStatus: helperStatus)
                case .uninstall, .optimize, .status:
                    ComingSoonView(module: selection)
                }
            }
            .frame(minWidth: 520, minHeight: 420)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct ComingSoonView: View {
    let module: ShellModule

    var body: some View {
        VStack(spacing: VoleTheme.Spacing.md) {
            Text(module.title)
                .font(VoleTheme.TypeScale.title())
            Text("即将推出")
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoleTheme.Colors.contentBackground)
    }
}
