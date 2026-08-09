import SwiftUI

/// Caption + metric — no progress / strata bar chrome.
struct SoilPanel: View {
    var valueText: String
    var caption: String

    var body: some View {
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
        .accessibilityElement(children: .combine)
    }
}
