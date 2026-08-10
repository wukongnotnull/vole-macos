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
    static let checkboxSize: CGFloat = 14
    /// Dense list row insets (vertical).
    static let rowVerticalPadding: CGFloat = 3
    /// Row primary label — regular, smaller than body.
    static func rowTitleFont() -> Font { .system(size: 12, weight: .regular, design: .default) }
    /// Row size column — regular tabular.
    static func rowMetricFont() -> Font { .system(size: 11, weight: .regular, design: .monospaced) }
    /// Secondary path under leaf title.
    static func rowPathFont() -> Font { .system(size: 10, weight: .regular, design: .monospaced) }
    /// Header eyebrow — matches caption density.
    static func headerEyebrowFont() -> Font { .system(size: 10, weight: .regular, design: .rounded) }
    /// Header title — slightly above row title, regular weight.
    static func headerTitleFont() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    /// Header selected-bytes figure — same weight family as row metrics.
    static func headerMetricFont() -> Font { .system(size: 13, weight: .regular, design: .monospaced) }
    static let headerStackSpacing: CGFloat = 2
    static let chromeControlSpacing: CGFloat = VoleTheme.Spacing.xs
    static let searchFieldHorizontalPadding: CGFloat = VoleTheme.Spacing.sm
    static let searchFieldVerticalPadding: CGFloat = VoleTheme.Spacing.xs
    static let chipVerticalPadding: CGFloat = 4
}

/// Circular checkbox using Fur brand accent (not system blue).
struct VoleCircularCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: CleanCandidatesListStyle.chromeControlSpacing) {
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
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(CleanCandidatesListStyle.filterChipSelectedLabel)
                    }
                }
                .frame(width: 18, height: 18)

                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
