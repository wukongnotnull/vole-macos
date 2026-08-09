import SwiftUI

enum SoilStrataMode: Equatable {
    case idle
    case indeterminate
    case determinate(Double)
}

enum SoilIndeterminatePresentation: Equatable {
    /// Static measure ticks — no sweeping segment as the progress cue.
    case staticMeasure
}

/// Signature "soil strata" seam: a thin core-sample band for Clean volume.
/// - idle (`fraction` nil, not indeterminate): soft ticks — 待扫描
/// - indeterminate: static measure band (mascot owns busy motion)
/// - determinate: 0...1 filled share with easing
struct SoilStrataView: View {
    let fraction: Double?
    var indeterminate: Bool = false
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var clampedFraction: Double? {
        fraction.map { min(max($0, 0), 1) }
    }

    var mode: SoilStrataMode {
        if indeterminate { return .indeterminate }
        if let f = clampedFraction { return .determinate(f) }
        return .idle
    }

    var indeterminatePresentation: SoilIndeterminatePresentation { .staticMeasure }
    var indeterminateUsesSweep: Bool { false }

    private var prefersReducedMotion: Bool { reduceMotion || !animated }

    private let seamHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VoleTheme.Colors.molehill.opacity(mode == .idle ? 0.55 : 0.28))

                switch mode {
                case .idle:
                    // Soft ticks — waiting to dig, not a chunky barcode.
                    measureTicks(width: geo.size.width, fill: VoleTheme.Colors.molehill)
                case .indeterminate:
                    // Static measure band — progress feel lives on the mascot, not a sweep.
                    ZStack {
                        measureTicks(width: geo.size.width, fill: VoleTheme.Colors.fur.opacity(0.72))
                        Capsule()
                            .fill(VoleTheme.Colors.soil.opacity(0.28))
                            .frame(width: geo.size.width * 0.42, height: seamHeight)
                    }
                case .determinate(let f):
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

    private func measureTicks(width: CGFloat, fill: Color) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<Int(max(width / 18, 3)), id: \.self) { _ in
                Capsule()
                    .fill(fill)
                    .frame(width: 8, height: seamHeight)
            }
        }
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
        switch mode {
        case .determinate(let f):
            return Text("可回收体积占比 \(Int((f * 100).rounded()))%")
        case .indeterminate:
            return Text("进行中")
        case .idle:
            return Text("待扫描")
        }
    }
}
