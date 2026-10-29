import Foundation

struct StorageEntry: Identifiable, Sendable {
    let url: URL
    let bytes: Int64
    let isDirectory: Bool
    var id: String { url.path }
    var name: String { url.lastPathComponent }
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
}

struct StorageSnapshot {
    var entries: [StorageEntry] = []
    var scannedAt: Date?
    var isScanning = false
    var error: String?
    var skippedItems = 0
    var scannedItems = 0
}
