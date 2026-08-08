import SwiftUI

struct ShellView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var selection: ShellModule = .clean

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)
                .frame(width: 200)
                .padding(VoleTheme.Spacing.md)
                .background(VoleTheme.Colors.canvas)

            detailView
                .padding(VoleTheme.Spacing.md)
                .background(VoleTheme.Colors.canvas)
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    @ViewBuilder
    private var detailView: some View {
        Group {
            switch selection {
            case .clean:
                CleanRootView(session: session, helperStatus: helperStatus)
            case .uninstall, .optimize, .status:
                ComingSoonView(module: selection)
            }
        }
        .background(VoleTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
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
    }
}
