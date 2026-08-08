import Foundation

let service = HelperXPCService()
let listener = NSXPCListener(machServiceName: HelperServiceIDs.machServiceName)
listener.delegate = service
listener.resume()
RunLoop.current.run()
