import Foundation

/// Sidecar apply progress as a 0...1 fraction when a total is known; otherwise `nil`
/// (caller should show indeterminate strata).
func applyProgressFraction(scanned: UInt64, total: Int) -> Double? {
    guard total > 0 else { return nil }
    return min(1, Double(scanned) / Double(total))
}

/// Helper / unknown-total phases fall back to indeterminate soil motion.
func applyUsesIndeterminateProgress(scanned: UInt64, total: Int, progressCurrent: String) -> Bool {
    if progressCurrent.contains("助手") { return true }
    return applyProgressFraction(scanned: scanned, total: total) == nil
}

func applyProgressValueText(scanned: UInt64, total: Int) -> String {
    "\(scanned) / \(total)"
}
