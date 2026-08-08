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
            Spacer(minLength: VoleTheme.Spacing.md)
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
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
    }

    private var brandHeader: some View {
        VStack(spacing: VoleTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x5A473B), VoleTheme.Colors.ink],
                            center: .init(x: 0.5, y: 0.3),
                            startRadius: 6,
                            endRadius: 28
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                Image("VoleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .accessibilityLabel("Vole 标志")
            }
            VStack(spacing: 1) {
                Text("Vole")
                    .font(VoleTheme.TypeScale.headline())
                    .foregroundStyle(VoleTheme.Colors.onInk)
                Text("BURROW & SORT")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.4))
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
            .frame(width: 32, height: 32)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Vole 标志")
            .padding(.bottom, VoleTheme.Spacing.xs)
    }

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ShellModule.allCases) { module in
                Button {
                    selection = module
                } label: {
                    HStack(spacing: VoleTheme.Spacing.sm) {
                        Image(systemName: module.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 18, alignment: .center)
                        Text(module.title)
                            .font(VoleTheme.TypeScale.body())
                        Spacer(minLength: 0)
                        if !module.isAvailable {
                            Text("未开")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.35))
                        }
                    }
                    .padding(.horizontal, VoleTheme.Spacing.sm)
                    .padding(.vertical, 9)
                    .foregroundStyle(foreground(for: module))
                    .background(background(for: module))
                    .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
                }
                .buttonStyle(.plain)
                .disabled(!module.isAvailable)
                .help(module.isAvailable ? module.title : "\(module.title) · 即将推出")
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
                .help(module.isAvailable ? module.title : "\(module.title) · 即将推出")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var collapsedFooter: some View {
        Button {
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.55))
        }
        .buttonStyle(.plain)
        .help("设置")
        .frame(maxWidth: .infinity)
    }

    private var moreRow: some View {
        Button {
        } label: {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 18, alignment: .center)
                Text("设置")
                    .font(VoleTheme.TypeScale.caption())
                Spacer(minLength: 0)
            }
            .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.55))
            .padding(.horizontal, VoleTheme.Spacing.sm)
            .padding(.vertical, VoleTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .help("设置")
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
        return VoleTheme.Colors.onInk.opacity(module.isAvailable ? 0.92 : 0.45)
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
