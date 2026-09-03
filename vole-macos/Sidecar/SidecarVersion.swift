import Foundation

enum SidecarVersion {
    static let requiredExactEmbedded = "2.20.0"

    static func parse(_ raw: String) -> (major: Int, minor: Int, patch: Int)? {
        let firstLine = raw.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)\.(\d+)\.(\d+)"#) else {
            return nil
        }
        let ns = firstLine as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: firstLine, range: range),
              match.numberOfRanges >= 4,
              let major = Int(ns.substring(with: match.range(at: 1))),
              let minor = Int(ns.substring(with: match.range(at: 2))),
              let patch = Int(ns.substring(with: match.range(at: 3)))
        else {
            return nil
        }
        return (major, minor, patch)
    }

    static func supportsWorktreeAgent(_ raw: String) -> Bool {
        guard let v = parse(raw) else { return false }
        return v.major == 2 && v.minor == 20
    }
}
