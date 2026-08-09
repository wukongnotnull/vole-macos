import SwiftUI

struct SidebarView: View {
    @Binding var selection: ShellModule
    @Binding var showSettings: Bool
    @ObservedObject var helperStatus: HelperStatusModel
    var mascotActivity: MascotActivity = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            brandHeader
            moduleList
                .padding(.horizontal, VoleTheme.Spacing.sm)
            Spacer(minLength: VoleTheme.Spacing.md)
            SidebarRootHelperRow(model: helperStatus)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(VoleTheme.Colors.onInk.opacity(0.08))
                        .frame(height: 1)
                }
            moreRow
                .padding(.horizontal, VoleTheme.Spacing.sm)
        }
        // Top inset clears floating traffic lights.
        .padding(.top, 36)
        .padding(.bottom, VoleTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
