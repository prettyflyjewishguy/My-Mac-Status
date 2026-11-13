import SwiftUI
import AppKit

struct UpdateIntelligenceView: View {
    @State private var result: UpdateReadinessResult?
    @State private var checking = false

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                        .foregroundStyle(.green)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("macOS Update Intelligence").font(.headline)
                        Text("See available macOS updates and whether your Mac is ready.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Button(checking ? "Checking…" : "Check for Updates") { check() }
                        .disabled(checking)
                }
                if checking { ProgressView("Checking Software Update…") }
                if let result {
                    Divider()
                    Label(result.installed, systemImage: "desktopcomputer")
                        .font(.subheadline.weight(.semibold))
                    HStack(alignment: .top, spacing: 12) {
                        resultTile("Availability", value: result.availability, symbol: "arrow.down.circle")
                        resultTile("Readiness", value: result.readiness, symbol: "checkmark.shield")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Recommendation", systemImage: "lightbulb")
                            .font(.subheadline.weight(.semibold))
                        Text(result.recommendation)
                            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(result.findings, id: \.self) { finding in
                                Label {
                                    Text(finding).font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                } icon: {
                                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                                }
                            }
                        }.padding(.vertical, 5)
                    } label: {
                        Text("Why am I seeing this?")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Last checked: " + result.checkedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                } else if !checking {
                    Text("Check what macOS is offering. This won’t download or install anything.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer(minLength: 0)
                    Button("Open Software Update") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                    }
                }
            }
        }
    }

    private func resultTile(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
        .padding(11)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }

    private func check() {
        guard !checking else { return }
        checking = true
        Task.detached(priority: .userInitiated) {
            let snapshot = UpdateIntelligenceService.check()
            await MainActor.run {
                result = snapshot
                checking = false
            }
        }
    }
}
