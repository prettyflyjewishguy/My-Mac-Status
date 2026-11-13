import SwiftUI

struct DiagnosticsRepairView: View {
    @EnvironmentObject private var model: CompanionModel
    @State private var running = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Read-only diagnostics").font(.headline)
            InfoPanel(tint: CompanionStyle.StatusTone.informational.color) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Management enrollment: \(model.macHealth.checks.first(where: { $0.id == "mdm" })?.value ?? "Not checked")")
                    Text("An unmanaged Mac is not unhealthy. These checks do not change settings or attempt repairs.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Check Again") { runChecks() }.disabled(running)
                        Button("Refresh Mac Status") { model.refresh() }.disabled(model.loading)
                    }
                }
            }
            Text("Connection & Device Checks").font(.headline)
            if model.diagnosticHistory.isEmpty { Text("No diagnostics run yet.").foregroundStyle(.secondary) }
            ForEach(model.diagnosticHistory.prefix(30)) { record in
                InfoPanel(tint: record.succeeded ? CompanionStyle.StatusTone.healthy.color : CompanionStyle.StatusTone.warning.color) {
                    HStack {
                        Image(systemName: record.succeeded ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(record.succeeded ? CompanionStyle.StatusTone.healthy.color : CompanionStyle.StatusTone.warning.color)
                        VStack(alignment: .leading) {
                            Text(record.name)
                            Text("\(record.result) · \(record.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            if !model.diagnosticHistory.isEmpty {
                Button("Clear History", role: .destructive) { model.diagnosticHistory.removeAll() }
            }
            Text("History is informational and never changes current recommendations.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func runChecks() {
        running = true
        Task.detached(priority: .utility) {
            let records = CommunityDiagnosticService.run()
            await MainActor.run {
                model.diagnosticHistory.insert(contentsOf: records, at: 0)
                model.diagnosticHistory = Array(model.diagnosticHistory.prefix(200))
                running = false
            }
        }
    }
}
