import SwiftUI

/// Token mapping for Clean candidates list chrome (selection, chips, rows).
enum CleanCandidatesListStyle {
    static var selectionFill: Color { VoleTheme.Colors.fur }
    static var filterChipSelectedFill: Color { VoleTheme.Colors.fur }
    static var filterChipSelectedLabel: Color { VoleTheme.Colors.onFur }
    static var filterChipIdleFill: Color { VoleTheme.Colors.molehill.opacity(0.55) }
    static var filterChipIdleLabel: Color { VoleTheme.Colors.text }
    static var searchFieldFill: Color { VoleTheme.Colors.molehill.opacity(0.35) }
    static var sortChipFill: Color { VoleTheme.Colors.molehill.opacity(0.45) }
    static var rowSeparator: Color { VoleTheme.Colors.molehill.opacity(0.55) }
    static var columnHeaderLabel: some ShapeStyle { .secondary }
    static var sizeLabel: some ShapeStyle { .secondary }
    static var pathLabel: some ShapeStyle { .tertiary }
    static let checkboxSize: CGFloat = 16
    static let rowVerticalPadding: CGFloat = VoleTheme.Spacing.sm
}

/// Circular checkbox using Fur brand accent (not system blue).
struct VoleCircularCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: VoleTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            configuration.isOn
                                ? CleanCandidatesListStyle.selectionFill
                                : VoleTheme.Colors.molehill,
                            lineWidth: 1.5
                        )
                        .background(
                            Circle().fill(
                                configuration.isOn
                                    ? CleanCandidatesListStyle.selectionFill
                                    : Color.clear
                            )
                        )
                        .frame(
                            width: CleanCandidatesListStyle.checkboxSize,
                            height: CleanCandidatesListStyle.checkboxSize
                        )

                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(CleanCandidatesListStyle.filterChipSelectedLabel)
                    }
                }
                .frame(width: 22, height: 22)

                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
