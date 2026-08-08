import SwiftUI

/// Strata band + tabular value + caption. Used across Clean states.
struct SoilPanel: View {
    let fraction: Double?
    var valueText: String
    var caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            SoilStrataView(fraction: fraction)
            HStack(alignment: .firstTextBaseline) {
                Text(caption)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueText)
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(.primary)
            }
        }
        .padding(VoleTheme.Spacing.md)
        .background(Color(.windowBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VoleTheme.Radius.card)
                .stroke(VoleTheme.Colors.molehill, lineWidth: 1)
        )
    }
}
