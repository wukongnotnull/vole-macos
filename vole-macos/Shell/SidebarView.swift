import SwiftUI

struct SidebarView: View {
    @Binding var selection: ShellModule
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            brandHeader
            moduleList
            Spacer(minLength: VoleTheme.Spacing.md)
            moreRow
        }
        // Top inset clears floating traffic lights.
        .padding(.top, 36)
        .padding(.horizontal, VoleTheme.Spacing.sm)
        .padding(.bottom, VoleTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoleTheme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .shadow(color: VoleTheme.Shadow.card, radius: 3, x: 0, y: 1)
    }

    private var brandHeader: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x5A473B), VoleTheme.Colors.ink],
                        center: .init(x: 0.5, y: 0.3),
                        startRadius: 12,
                        endRadius: 52
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            Image("VoleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .accessibilityLabel("Vole 标志")
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, VoleTheme.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VoleTheme.Colors.onInk.opacity(0.08))
                .frame(height: 1)
        }
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

    private var moreRow: some View {
        Button {
            showSettings = true
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
