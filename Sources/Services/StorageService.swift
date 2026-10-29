import Foundation

// Read-only analysis. Does not remove, move, or modify files.
enum StorageService {
    struct Result: Sendable {
        let entries: [StorageEntry]
        let scannedItems: Int
        let skippedItems: Int
        let error: String?
    }

    static func scanHome() -> Result {
        let manager = FileManager.default
        let home = manager.homeDirectoryForCurrentUser
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .isDirectoryKey]
        guard let enumerator = manager.enumerator(at: home, includingPropertiesForKeys: Array(keys), options: [.skipsPackageDescendants], errorHandler: { _, _ in true }) else {
            return Result(entries: [], scannedItems: 0, skippedItems: 0, error: "Unable to access your home folder.")
        }
        var files: [StorageEntry] = []
        var directorySizes: [URL: Int64] = [:]
        var scanned = 0
        var skipped = 0
        for case let url as URL in enumerator {
            do {
                let values = try url.resourceValues(forKeys: keys)
                if values.isSymbolicLink == true { skipped += 1; continue }
                if values.isRegularFile != true { continue }
                scanned += 1
                let size = Int64(max(0, values.fileSize ?? 0))
                files.append(StorageEntry(url: url, bytes: size, isDirectory: false))
                // Aggregate file sizes into each parent directory under the home folder.
                var parent = url.deletingLastPathComponent()
                while parent.path.hasPrefix(home.path + "/") {
                    directorySizes[parent, default: 0] += size
                    let next = parent.deletingLastPathComponent()
                    if next == parent { break }
                    parent = next
                }
            } catch { skipped += 1 }
        }
        let topFiles = files.sorted { $0.bytes > $1.bytes }.prefix(50)
        let topFolders = directorySizes.map { StorageEntry(url: $0.key, bytes: $0.value, isDirectory: true) }
            .sorted { $0.bytes > $1.bytes }.prefix(50)
        return Result(entries: Array(topFiles) + Array(topFolders), scannedItems: scanned,
                      skippedItems: skipped, error: nil)
    }
}
