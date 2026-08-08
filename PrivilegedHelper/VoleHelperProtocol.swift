import Foundation

/// Keep in sync with `vole-macos/Privilege/VoleHelperProtocol.swift` until a shared target exists.
@objc protocol VoleHelperProtocol {
    func ping(reply: @escaping (_ pid: Int32, _ uid: Int32) -> Void)
}
