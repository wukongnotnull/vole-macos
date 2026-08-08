import Foundation

/// Keep in sync with `vole-macos/Privilege/VoleHelperProtocol.swift` until a shared target exists.
@objc protocol VoleHelperProtocol {
    func ping(reply: @escaping (_ pid: Int32, _ uid: Int32) -> Void)
    func removeAuthorizedPaths(
        _ paths: [String],
        reply: @escaping (_ ok: Bool, _ error: String?) -> Void
    )
    func bootoutLaunchdLabel(
        _ label: String,
        reply: @escaping (_ ok: Bool, _ error: String?) -> Void
    )
}
