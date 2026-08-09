import SwiftUI

struct AnalyzeRootView: View {
    @ObservedObject var session: AnalyzeSession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Analyze · 分析")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("目录体积")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                if session.canGoUp {
                    Button("上一级") { session.goUp() }
                        .disabled(session.isScanning)
                }
                Button("选择文件夹") { session.chooseFolder() }
                    .disabled(session.isScanning)
                if session.isScanning {
                    Button("取消") { session.cancel() }
                } else {
                    Button("重新扫描") { session.rescan() }
                }
            }

            Text(session.currentPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)

            SoilPanel(
                fraction: nil,
                valueText: ByteFormat.string(UInt64(clamping: max(session.totalSize, 0))),
                caption: session.isScanning
                    ? "扫描中…"
                    : filesCaption
            )

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            List {
                ForEach(session.entries) { entry in
                    entryRow(entry)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            if !session.largeFiles.isEmpty {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("大文件")
                        .font(VoleTheme.TypeScale.body().weight(.semibold))
                    ForEach(session.largeFiles.prefix(8)) { file in
                        HStack {
                            Text(file.name)
                                .font(VoleTheme.TypeScale.caption())
                                .lineLimit(1)
                            Spacer()
                            Text(ByteFormat.string(UInt64(clamping: max(file.size, 0))))
                                .font(VoleTheme.TypeScale.metric())
                                .foregroundStyle(.secondary)
                        }
                        Text(file.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            if session.entries.isEmpty && !session.isScanning {
                session.rescan()
            }
        }
    }

    private var filesCaption: String {
        if let total = session.totalFiles {
            return "\(total) 个文件 · \(session.entries.count) 项"
        }
        return "\(session.entries.count) 项"
    }

    @ViewBuilder
    private func entryRow(_ entry: AnalyzeEntryItem) -> some View {
        Button {
            if entry.isDir {
                session.enterDirectory(entry.path)
            }
        } label: {
            HStack {
                Image(systemName: entry.isDir ? "folder.fill" : "doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(entry.isDir ? VoleTheme.Colors.fur : .secondary)
                    .frame(width: 18)
                Text(entry.name)
                    .font(VoleTheme.TypeScale.body())
                    .foregroundStyle(VoleTheme.Colors.text)
                    .lineLimit(1)
                Spacer()
                Text(ByteFormat.string(UInt64(clamping: max(entry.size, 0))))
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!entry.isDir || session.isScanning)
    }
}
