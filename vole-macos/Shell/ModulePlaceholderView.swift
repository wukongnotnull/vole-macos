import SwiftUI

struct ModulePlaceholderView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            Text(title)
                .font(VoleTheme.TypeScale.title())
                .foregroundStyle(VoleTheme.Colors.text)
            Text("模块加载中…")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}
