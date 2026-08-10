import Foundation

enum ByteFormat {
    static func string(_ bytes: UInt64) -> String {
        // Locale-stable zero: ByteCountFormatter can emit "Zero bytes".
        if bytes == 0 { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    }
}
