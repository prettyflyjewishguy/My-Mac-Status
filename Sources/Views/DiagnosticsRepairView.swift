import SwiftUI

struct DiagnosticsRepairView: View {
    @EnvironmentObject private var model: CompanionModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Read-only device management diagnostics").font(.headline)
            InfoPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Management enrollment").font(.headline)
                    Text(model.macHealth.checks.first(where: { $0.id == "mdm" })?.value ?? "Not checked")
                    Text("This edition checks macOS MDM enrollment without assuming a specific MDM vendor. It does not execute management repair policies.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Refresh diagnostics") { model.refresh() }.disabled(model.loading)
                }
            }
            InfoPanel {
                Text("If your Mac has management or connectivity problems, contact your organization's support team.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
