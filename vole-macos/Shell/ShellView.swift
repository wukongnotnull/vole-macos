import SwiftUI
import AppKit

/// Applies full-size content + transparent title so the canvas reaches the top edge,
/// keeping only the traffic-light controls.
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            Self.applyChrome(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        Self.applyChrome(to: nsView.window)
    }

    private static func applyChrome(to window: NSWindow?) {
        guard let window else { return }
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.toolbar = nil
    }
}

struct ShellView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var selection: ShellModule = .clean

    private let sidebarWidth: CGFloat = 168
    private let sidebarGutter: CGFloat = VoleTheme.Spacing.xs
    private var sidebarColumnWidth: CGFloat { sidebarWidth + sidebarGutter * 2 }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            SidebarView(selection: $selection)
                .frame(width: sidebarWidth)
                .padding(.leading, sidebarGutter)
                .padding(.trailing, sidebarGutter)
                .padding(.top, sidebarGutter)
                .padding(.bottom, sidebarGutter)
                .frame(width: sidebarColumnWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(VoleTheme.Colors.canvas)

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.trailing, sidebarGutter)
                .padding(.top, sidebarGutter)
                .padding(.bottom, sidebarGutter)
                .background(VoleTheme.Colors.canvas)
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(VoleTheme.Colors.canvas)
        .background(WindowAccessor())
        // Draw under the transparent titlebar; traffic lights float on the sidebar.
        .ignoresSafeArea(.container, edges: .top)
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
