import SwiftUI

/// Thin strata seam + caption + metric — no nested card chrome.
struct SoilPanel: View {
    let fraction: Double?
    var valueText: String
    var caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            SoilStrataView(fraction: fraction)

            HStack(alignment: .firstTextBaseline, spacing: VoleTheme.Spacing.sm) {
                Text(caption)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(valueText)
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(VoleTheme.Colors.text)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}
