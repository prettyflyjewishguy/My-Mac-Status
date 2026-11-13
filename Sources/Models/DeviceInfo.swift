import Foundation

struct DeviceInfo {
    var computerName = "Unavailable"
    var model = "Unavailable"
    var serial = "Unavailable"
    var macOS = "Unavailable"
    var processor = "Unavailable"
    var freeBytes: Int64?
    // Reclaimable capacity macOS considers available for important user operations.
    var availableBytes: Int64?
    var totalBytes: Int64?
    var captured = Date()
}
