import SwiftUI

/// Signature "soil strata" band: volume narrative for Clean.
/// `fraction`: nil = idle (待扫描), 0...1 = selected/progress/recovered share.
struct SoilStrataView: View {
    let fraction: Double?
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var clampedFraction: Double? {
        fraction.map { min(max($0, 0), 1) }
    }

    private var prefersReducedMotion: Bool { reduceMotion || !animated }

    private var isIdle: Bool { fraction == nil }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                idleTrack(width: geo.size.width)
                if let f = clampedFraction {
                    RoundedRectangle(cornerRadius: VoleTheme.Radius.strata)
                        .fill(strataGradient)
                        .frame(width: max(geo.size.width * f, 12))
                        .animation(prefersReducedMotion ? nil : VoleTheme.Motion.easing, value: f)
                }
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.strata))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var strataGradient: LinearGradient {
        LinearGradient(
            colors: [VoleTheme.Colors.soil, VoleTheme.Colors.strataMid, VoleTheme.Colors.fur, VoleTheme.Colors.molehill],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    private func idleTrack(width: CGFloat) -> some View {
        if isIdle {
            HStack(spacing: VoleTheme.Spacing.sm) {
                ForEach(0..<Int(max(width / 22, 4)), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(VoleTheme.Colors.molehill)
                        .frame(width: 14, height: 12)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: VoleTheme.Radius.strata)
                .fill(VoleTheme.Colors.molehill.opacity(0.35))
        }
    }

    private var accessibilityText: Text {
        if let f = clampedFraction {
            return Text("可回收体积占比 \(Int((f * 100).rounded()))%")
        }
        return Text("待扫描")
    }
}
