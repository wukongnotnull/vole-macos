import SwiftUI

/// Signature "soil strata" seam: a thin core-sample band for Clean volume.
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

    private let seamHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VoleTheme.Colors.molehill.opacity(isIdle ? 0.55 : 0.28))

                if isIdle {
                    // Soft ticks — waiting to dig, not a chunky barcode.
                    HStack(spacing: 10) {
                        ForEach(0..<Int(max(geo.size.width / 18, 3)), id: \.self) { _ in
                            Capsule()
                                .fill(VoleTheme.Colors.molehill)
                                .frame(width: 8, height: seamHeight)
                        }
                    }
                } else if let f = clampedFraction {
                    Capsule()
                        .fill(strataGradient)
                        .frame(width: max(geo.size.width * CGFloat(f), seamHeight))
                        .animation(prefersReducedMotion ? nil : VoleTheme.Motion.easing, value: f)
                }
            }
        }
        .frame(height: seamHeight)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Soil → fur body, sage only as the thin terminal tip (geological seam, not neon bar).
    private var strataGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: VoleTheme.Colors.soil, location: 0),
                .init(color: VoleTheme.Colors.strataMid, location: 0.45),
                .init(color: VoleTheme.Colors.fur, location: 0.82),
                .init(color: VoleTheme.Colors.sage, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var accessibilityText: Text {
        if let f = clampedFraction {
            return Text("可回收体积占比 \(Int((f * 100).rounded()))%")
        }
        return Text("待扫描")
    }
}
