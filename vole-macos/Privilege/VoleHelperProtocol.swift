import Foundation

/// Keep in sync with `PrivilegedHelper/VoleHelperProtocol.swift` until a shared target exists.
@objc protocol VoleHelperProtocol {
    func ping(reply: @escaping (_ pid: Int32, _ uid: Int32) -> Void)
}
