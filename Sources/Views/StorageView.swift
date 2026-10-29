import SwiftUI
import AppKit

struct StorageView: View {
    @EnvironmentObject private var model: CompanionModel
    // Tab selection lives in the existing observable model to avoid SwiftUI macro plugin issues.
    private var entries: [StorageEntry] {
        model.storage.entries.filter { $0.isDirectory == (model.storageSelectedTab == 1) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            Text("Explore storage on your Mac").font(.title3.weight(.semibold))
            Text("Find large files and folders to help manage your storage. No files will be changed or removed.")
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                MetricCard(title: "Free Storage", value: formatted(model.device.freeBytes), symbol: "internaldrive")
                MetricCard(title: "Total Storage", value: formatted(model.device.totalBytes), symbol: "externaldrive")
            }
            InfoPanel {
                HStack(spacing: 14) {
                    Image(systemName: "folder.badge.magnifyingglass").font(.title2).foregroundStyle(CompanionStyle.green)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Home Folder Analysis").font(.headline)
                        Text(model.storage.scannedAt.map { "Last scanned: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Not scanned yet")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(model.storage.isScanning ? "Scanning…" : "Scan Home Folder") { model.scanStorage() }
                        .disabled(model.storage.isScanning)
                        .buttonStyle(.borderedProminent)
                }
                if model.storage.isScanning {
                    ProgressView().controlSize(.small).padding(.top, 10)
                    Text("Scanning files. Large home folders may take several minutes.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let error = model.storage.error {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            }
            if model.storage.scannedAt != nil {
                Picker("Results", selection: $model.storageSelectedTab) {
                    Text("Largest Files").tag(0)
                    Text("Largest Folders").tag(1)
                }.pickerStyle(.segmented)
                Text("Top 50 by logical file size · \(model.storage.scannedItems) files inspected")
                    .font(.caption).foregroundStyle(.secondary)
                if entries.isEmpty {
                    InfoPanel { Text("No accessible items were found.").foregroundStyle(.secondary) }
                } else {
                    LazyVStack(spacing: 9) {
                        ForEach(entries) { entry in
                            InfoPanel {
                                HStack(spacing: 12) {
                                    Image(systemName: entry.isDirectory ? "folder" : "doc")
                                        .foregroundStyle(CompanionStyle.green).frame(width: 25)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.name).font(.subheadline.weight(.medium)).lineLimit(1)
                                        Text(entry.url.path).font(.caption).foregroundStyle(.secondary)
                                            .lineLimit(1).truncationMode(.middle).help(entry.url.path)
                                            .lineLimit(1).truncationMode(.middle).help(entry.url.path)
                                    }
                                    Spacer(minLength: 10)
                                    Text(entry.formattedSize).font(.subheadline.monospacedDigit()).lineLimit(1)
                                    Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([entry.url]) }
                                        .buttonStyle(.bordered).help("Reveal in Finder")
                                }
                            }
                        }
                    }
                }
                if model.storage.skippedItems > 0 {
                    Text("Some files were inaccessible or skipped. Folder totals are estimates based on readable files, not disk allocation.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            InfoPanel {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundStyle(CompanionStyle.green)
                    Text("Review large downloads and unused files in Finder. Folder sizes are estimates, and some protected locations are not included.")
                        .font(.callout)
                }
            }
        }
    }
    private func formatted(_ bytes: Int64?) -> String {
        guard let bytes else { return "Information unavailable" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
