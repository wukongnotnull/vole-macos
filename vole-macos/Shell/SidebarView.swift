import SwiftUI

struct SidebarView: View {
    @Binding var selection: ShellModule

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            brandHeader
            moduleList
            Spacer()
            moreRow
        }
        .padding(.vertical, VoleTheme.Spacing.md)
        .padding(.horizontal, VoleTheme.Spacing.sm)
        .background(VoleTheme.Colors.burrow)
    }

    private var brandHeader: some View {
        VStack(spacing: VoleTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x4A352C), VoleTheme.Colors.burrow],
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
                    .foregroundStyle(VoleTheme.Colors.onBurrow)
                Text("BURROW & SORT")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(VoleTheme.Colors.onBurrow.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, VoleTheme.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VoleTheme.Colors.onBurrow.opacity(0.06))
                .frame(height: 1)
        }
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

    private var moreRow: some View {
        Text("更多 · 设置")
            .font(VoleTheme.TypeScale.caption())
            .foregroundStyle(VoleTheme.Colors.onBurrow.opacity(0.45))
            .padding(.horizontal, VoleTheme.Spacing.sm)
            .padding(.vertical, VoleTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(VoleTheme.Colors.onBurrow.opacity(0.06))
                    .frame(height: 1)
            }
    }

    private func foreground(for module: ShellModule) -> Color {
        if selection == module {
            return VoleTheme.Colors.burrow
        }
        return VoleTheme.Colors.onBurrow.opacity(module.isAvailable ? 1 : 0.4)
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
