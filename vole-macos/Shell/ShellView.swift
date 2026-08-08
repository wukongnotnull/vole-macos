import SwiftUI
import AppKit

/// Applies full-size content + transparent title so the canvas reaches the top edge,
/// keeping only the traffic-light controls.
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.toolbar = nil
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ShellView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var selection: ShellModule = .clean
    @State private var sidebarCollapsed = false

    private var sidebarWidth: CGFloat { sidebarCollapsed ? 64 : 200 }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .top) {
                SidebarView(selection: $selection, isCollapsed: $sidebarCollapsed)
                    .frame(width: sidebarWidth)
                    .padding(.horizontal, VoleTheme.Spacing.md)
                    .padding(.vertical, VoleTheme.Spacing.md)

                // Traffic-light row overlay: toggle floats on the same line as
                // the window controls, without reserving layout height.
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 78)
                    collapseToggle
                    Spacer()
                }
                .frame(height: 28)
                .padding(.top, 6)
            }
            .background(VoleTheme.Colors.canvas)

            detailView
                .padding(.horizontal, VoleTheme.Spacing.md)
                .padding(.vertical, VoleTheme.Spacing.md)
                .background(VoleTheme.Colors.canvas)
        }
        .frame(minWidth: 720, minHeight: 480)
        .animation(VoleTheme.Motion.easing, value: sidebarCollapsed)
    }

    private var collapseToggle: some View {
        Button {
            withAnimation(VoleTheme.Motion.easing) {
                sidebarCollapsed.toggle()
            }
        } label: {
            Image(systemName: sidebarCollapsed ? "sidebar.left" : "sidebar.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VoleTheme.Colors.ink.opacity(0.7))
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sidebarCollapsed ? "展开侧栏" : "收起侧栏")
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
