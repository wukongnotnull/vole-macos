import SwiftUI

/// Shared vole mascot driven by `MascotActivity`.
/// Scanning = peek / dig-search; applying = haul / carry — visually distinct loops.
struct VoleMascotView: View {
    let state: MascotActivity
    var size: CGFloat = 44

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let motion = MascotMotion.profile(for: state, reduceMotion: reduceMotion)

        logo
            .modifier(MascotMotionModifier(kind: motion))
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(accessibilityValue(for: motion)))
            .accessibilityAddTraits(MascotMotion.isBusyAnnounced(for: motion) ? .updatesFrequently : [])
    }

    private var logo: some View {
        Image("VoleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    private var accessibilityLabel: String {
        "Vole 田鼠"
    }

    private func accessibilityValue(for motion: MascotMotionKind) -> String {
        if MascotMotion.isBusyAnnounced(for: motion) {
            switch state {
            case .scanning:
                return "扫描中"
            case .applying:
                return "清理中"
            default:
                return "进行中"
            }
        }
        switch state {
        case .success:
            return "完成"
        case .idle, .scanning, .applying:
            return ""
        }
    }
}

private struct MascotMotionModifier: ViewModifier {
    let kind: MascotMotionKind

    func body(content: Content) -> some View {
        switch kind {
        case .still, .stillBusy:
            content
        case .scanningLoop:
            content.modifier(ScanningMascotMotion())
        case .applyingLoop:
            content.modifier(ApplyingMascotMotion())
        case .successSettle:
            content.modifier(SuccessMascotMotion())
        }
    }
}

/// Peek / forage: bob + slight head tilt (searching the burrow).
private struct ScanningMascotMotion: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let bob = sin(t * 2 * .pi / 0.85) * 3.2
            let tilt = sin(t * 2 * .pi / 1.35) * 7
            let nudge = sin(t * 2 * .pi / 1.1) * 1.4
            content
                .offset(x: nudge, y: bob - 1.5)
                .rotationEffect(.degrees(tilt))
        }
    }
}

/// Dig / haul: deeper vertical dig stroke + lateral carry sway.
private struct ApplyingMascotMotion: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let dig = abs(sin(t * 2 * .pi / 0.7)) * 4.5
            let haul = sin(t * 2 * .pi / 1.05) * 5.5
            let roll = sin(t * 2 * .pi / 1.05) * 11
            let scale = 1.0 + abs(sin(t * 2 * .pi / 0.7)) * 0.04
            content
                .scaleEffect(scale)
                .offset(x: haul, y: dig)
                .rotationEffect(.degrees(roll))
        }
    }
}

/// Brief proud settle — one-shot scale, no loop.
private struct SuccessMascotMotion: ViewModifier {
    @State private var popped = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(popped ? 1.06 : 1.0)
            .offset(y: popped ? -1.5 : 0)
            .onAppear {
                withAnimation(VoleTheme.Motion.easing) {
                    popped = true
                }
            }
    }
}
