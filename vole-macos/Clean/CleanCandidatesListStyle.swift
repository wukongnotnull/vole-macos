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
    /// Command-strip title size (stronger than dense row title).
    static let headerTitleSize: CGFloat = 15
    /// Command-strip selected-bytes figure size.
    static let headerMetricSize: CGFloat = 15
    /// Header title — semibold rounded, baseline-paired with size metric.
    static func headerTitleFont() -> Font {
        .system(size: headerTitleSize, weight: .semibold, design: .rounded)
    }
    /// Header selected-bytes figure — tabular monospace, matches title weight.
    static func headerMetricFont() -> Font {
        .system(size: headerMetricSize, weight: .semibold, design: .monospaced)
    }
    static let headerStackSpacing: CGFloat = 2
    /// Vertical gap between command-strip top row (eyebrow/actions) and bottom row (title/size).
    static let headerCommandStripSpacing: CGFloat = VoleTheme.Spacing.sm
    static let headerActionBorderWidth: CGFloat = 1
    static let headerActionCornerRadius: CGFloat = VoleTheme.Radius.control
    /// Option 3 always keeps the "已选大小" caption under the figure.
    static let headerAlwaysShowsSizeCaption = true
    static let chromeControlSpacing: CGFloat = VoleTheme.Spacing.xs
    static let searchFieldHorizontalPadding: CGFloat = VoleTheme.Spacing.sm
    /// Filter-bar search / chip vertical inset — slightly taller than dense xs.
    static let searchFieldVerticalPadding: CGFloat = 6
    static let chipVerticalPadding: CGFloat = 6
    /// Filter-bar label size (search, chips, sort, root toggle).
    static let filterBarFontSize: CGFloat = 13
    static func filterBarFont(weight: Font.Weight = .regular) -> Font {
        .system(size: filterBarFontSize, weight: weight, design: .default)
    }
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
