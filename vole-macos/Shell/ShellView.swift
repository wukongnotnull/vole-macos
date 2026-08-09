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
    @StateObject private var uninstallSession = PlanModuleSession(kind: .uninstall)
    @StateObject private var optimizeSession = PlanModuleSession(kind: .optimize)
    @StateObject private var purgeSession = PlanModuleSession(kind: .purge)
    @StateObject private var installerSession = PlanModuleSession(kind: .installer)
    @StateObject private var analyzeSession = AnalyzeSession()
    @StateObject private var statusSession = StatusSession()
    @State private var selection: ShellModule = .clean
    @State private var showSettings = false

    private let sidebarWidth: CGFloat = 148
    private let sidebarGutter: CGFloat = VoleTheme.Spacing.xs
    private var sidebarColumnWidth: CGFloat { sidebarWidth + sidebarGutter * 2 }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            SidebarView(selection: $selection, showSettings: $showSettings)
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
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                helperStatus: helperStatus,
                voleVersion: session.voleVersion,
                onRefreshVersion: { session.refreshVersion() }
            )
        }
    }

    @ViewBuilder
    private var detailView: some View {
        Group {
            switch selection {
            case .clean:
                CleanRootView(session: session, helperStatus: helperStatus)
            case .uninstall:
                PlanModuleRootView(session: uninstallSession, helperStatus: helperStatus)
            case .optimize:
                PlanModuleRootView(session: optimizeSession, helperStatus: helperStatus)
            case .purge:
                PlanModuleRootView(session: purgeSession, helperStatus: helperStatus)
            case .installer:
                PlanModuleRootView(session: installerSession, helperStatus: helperStatus)
            case .analyze:
                AnalyzeRootView(session: analyzeSession)
            case .history:
                ModulePlaceholderView(title: "历史")
            case .status:
                StatusRootView(session: statusSession)
            }
        }
        .background(VoleTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
    }
}
