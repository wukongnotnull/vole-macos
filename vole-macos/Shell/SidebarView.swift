import SwiftUI

struct SidebarView: View {
    @Binding var selection: ShellModule
    @Binding var showSettings: Bool
    @ObservedObject var helperStatus: HelperStatusModel
    var mascotActivity: MascotActivity = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            brandHeader

            // Nav scrolls when the window is short; footer (root + 设置) stays pinned.
            ScrollView(.vertical, showsIndicators: false) {
                moduleList
                    .padding(.horizontal, VoleTheme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 0, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                SidebarRootHelperRow(model: helperStatus)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(VoleTheme.Colors.onInk.opacity(0.08))
                            .frame(height: 1)
                    }
                moreRow
                    .padding(.horizontal, VoleTheme.Spacing.sm)
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        // Top inset clears floating traffic lights.
        .padding(.top, 36)
        .padding(.bottom, VoleTheme.Spacing.md)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [VoleTheme.Colors.inkSun, VoleTheme.Colors.ink],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
    }

    private var brandHeader: some View {
        ZStack(alignment: .center) {
            // Soft sun bloom — keeps the clearing readable against warm soil.
            Circle()
                .fill(VoleTheme.Colors.fur.opacity(0.62))
                .frame(width: 132, height: 132)
                .blur(radius: 14)

            // Sunlit molehill mouth (sage matches app-icon ground).
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xF7F0E4),
                            VoleTheme.Colors.molehill,
                            VoleTheme.Colors.sage,
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 62
                    )
                )
                .frame(width: 118, height: 118)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    VoleTheme.Colors.onInk.opacity(0.55),
                                    VoleTheme.Colors.ink.opacity(0.2),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: Color(hex: 0x2C211C, alpha: 0.36), radius: 12, x: 0, y: 6)

            // Slightly larger than the disk so the vole peeks out of the burrow.
            // Asset bbox is ~1.6pt right / 0.7pt down at this size — nudge back to optical center.
            VoleMascotView(state: mascotActivity, size: 124)
                .offset(x: -1.6, y: -0.7)
                .shadow(color: Color(hex: 0x2C211C, alpha: 0.22), radius: 3, x: 0, y: 2)
        }
        .frame(width: 132, height: 132)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, VoleTheme.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VoleTheme.Colors.onInk.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, VoleTheme.Spacing.sm)
        }
    }

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ShellModule.allCases) { module in
                SidebarNavRow(
                    title: module.title,
                    systemImage: module.systemImage,
                    isSelected: selection == module,
                    isEnabled: module.isAvailable,
                    help: module.isAvailable ? module.title : "\(module.title) · 即将推出"
                ) {
                    selection = module
                }
            }
        }
    }

    private var moreRow: some View {
        SidebarNavRow(
            title: "设置",
            systemImage: "gearshape",
            isSelected: false,
            isEnabled: true,
            font: VoleTheme.TypeScale.caption(),
            iconWeight: .semibold,
            iconSize: 12,
            verticalPadding: VoleTheme.Spacing.sm,
            idleForegroundOpacity: 0.55,
            help: "设置"
        ) {
            showSettings = true
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(VoleTheme.Colors.onInk.opacity(0.08))
                .frame(height: 1)
        }
    }
}

/// Sidebar nav / settings row with full-width hit target and hover wash.
private struct SidebarNavRow: View {
    let title: String
    let systemImage: String
    var isSelected: Bool = false
    var isEnabled: Bool = true
    var font: Font = VoleTheme.TypeScale.body()
    var iconWeight: Font.Weight = .semibold
    var iconSize: CGFloat = 13
    var verticalPadding: CGFloat = 9
    var idleForegroundOpacity: Double = 0.92
    var help: String = ""
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: iconWeight))
                    .frame(width: 18, alignment: .center)
                Text(title)
                    .font(font)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, VoleTheme.Spacing.sm)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
            .contentShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(help)
        .onHover { hovering in
            guard isEnabled else { return }
            withAnimation(.easeOut(duration: VoleTheme.Motion.quick)) {
                isHovered = hovering
            }
        }
    }

    private var foreground: Color {
        if isSelected {
            return VoleTheme.Colors.onFur
        }
        let base = isEnabled ? idleForegroundOpacity : 0.45
        let boosted = min(base + 0.06, 1)
        return VoleTheme.Colors.onInk.opacity(isHovered ? boosted : base)
    }

    private var background: Color {
        if isSelected {
            return VoleTheme.Colors.fur
        }
        if isHovered && isEnabled {
            return VoleTheme.Colors.onInk.opacity(0.10)
        }
        return .clear
    }
}
