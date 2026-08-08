import SwiftUI

struct SidebarView: View {
    @Binding var selection: ShellModule
    @Binding var isCollapsed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            if isCollapsed {
                collapsedHeader
                collapsedModuleList
            } else {
                brandHeader
                moduleList
            }
            Spacer()
            if isCollapsed {
                collapsedFooter
            } else {
                moreRow
            }
        }
        // Top inset clears floating traffic lights + collapse toggle.
        .padding(.top, 44)
        .padding(.horizontal, VoleTheme.Spacing.sm)
        .padding(.bottom, VoleTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoleTheme.Colors.ink)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: VoleTheme.Radius.card,
                bottomTrailingRadius: VoleTheme.Radius.card,
                topTrailingRadius: VoleTheme.Radius.card
            )
        )
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
    }

    private var brandHeader: some View {
        VStack(spacing: VoleTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x5A473B), VoleTheme.Colors.ink],
                            center: .init(x: 0.5, y: 0.3),
                            startRadius: 8,
                            endRadius: 34
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                Image("VoleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .accessibilityLabel("Vole 标志")
            }
            VStack(spacing: 2) {
                Text("Vole")
                    .font(VoleTheme.TypeScale.headline())
                    .foregroundStyle(VoleTheme.Colors.onInk)
                Text("BURROW & SORT")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, VoleTheme.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VoleTheme.Colors.onInk.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var collapsedHeader: some View {
        Image("VoleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Vole 标志")
            .padding(.bottom, VoleTheme.Spacing.sm)
    }

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
            ForEach(ShellModule.allCases) { module in
                Button {
                    selection = module
                } label: {
                    HStack {
                        Text(module.title)
                            .font(VoleTheme.TypeScale.body())
                        Spacer()
                        if module.isAvailable {
                            Text("READY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .opacity(0.6)
                        } else {
                            Text("soon")
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .opacity(0.7)
                        }
                    }
                    .padding(.horizontal, VoleTheme.Spacing.sm)
                    .padding(.vertical, VoleTheme.Spacing.sm)
                    .foregroundStyle(foreground(for: module))
                    .background(background(for: module))
                    .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
                }
                .buttonStyle(.plain)
                .disabled(!module.isAvailable)
            }
        }
    }

    private var collapsedModuleList: some View {
        VStack(spacing: VoleTheme.Spacing.xs) {
            ForEach(ShellModule.allCases) { module in
                Button {
                    selection = module
                } label: {
                    Image(systemName: module.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(foreground(for: module))
                        .background(background(for: module))
                        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
                }
                .buttonStyle(.plain)
                .disabled(!module.isAvailable)
                .help(module.title)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var collapsedFooter: some View {
        // Placeholder: settings panel not implemented yet.
        Button {
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.6))
        }
        .buttonStyle(.plain)
        .help("设置")
        .frame(maxWidth: .infinity)
    }

    private var moreRow: some View {
        Text("更多 · 设置")
            .font(VoleTheme.TypeScale.caption())
            .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.6))
            .padding(.horizontal, VoleTheme.Spacing.sm)
            .padding(.vertical, VoleTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(VoleTheme.Colors.onInk.opacity(0.08))
                    .frame(height: 1)
            }
    }

    private func foreground(for module: ShellModule) -> Color {
        if selection == module {
            return VoleTheme.Colors.onFur
        }
        return VoleTheme.Colors.onInk.opacity(module.isAvailable ? 1 : 0.72)
    }

    @ViewBuilder
    private func background(for module: ShellModule) -> some View {
        if selection == module {
            VoleTheme.Colors.fur
        } else {
            Color.clear
        }
    }
}
