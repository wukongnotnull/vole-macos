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
    @State private var sidebarCollapsed = false

    private var sidebarWidth: CGFloat { sidebarCollapsed ? 64 : 200 }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Sidebar column extends under the titlebar so traffic lights sit on the ink card.
            ZStack(alignment: .topLeading) {
                SidebarView(selection: $selection, isCollapsed: $sidebarCollapsed)
                    .frame(width: sidebarWidth)
                    .padding(.leading, VoleTheme.Spacing.sm)
                    .padding(.trailing, VoleTheme.Spacing.md)
                    .padding(.top, 0)
                    .padding(.bottom, VoleTheme.Spacing.md)

                // Same row as traffic lights (leading ~70pt for system buttons).
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: 70)
                    collapseToggle
                    Spacer(minLength: 0)
                }
                .frame(height: 28)
                .padding(.leading, VoleTheme.Spacing.sm)
                .padding(.top, 10)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(VoleTheme.Colors.canvas)

            detailView
                .padding(.horizontal, VoleTheme.Spacing.md)
                .padding(.top, 8)
                .padding(.bottom, VoleTheme.Spacing.md)
                .background(VoleTheme.Colors.canvas)
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(VoleTheme.Colors.canvas)
        .background(WindowAccessor())
        // Draw under the transparent titlebar; traffic lights float on the sidebar.
        .ignoresSafeArea(.container, edges: .top)
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
                .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(VoleTheme.Colors.onInk.opacity(0.12))
                .clipShape(Circle())
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
