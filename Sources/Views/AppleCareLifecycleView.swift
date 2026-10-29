import SwiftUI

struct AppleCareLifecycleView: View {
    @EnvironmentObject private var model: CompanionModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Mac's hardware information").font(.headline)
            HStack(spacing: 12) {
                MetricCard(title: "Serial Number", value: model.device.serial, symbol: "number")
                MetricCard(title: "Model", value: model.device.model, symbol: "laptopcomputer")
            }
            InfoPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Lifecycle information not configured", systemImage: "calendar.badge.clock")
                        .font(.headline)
                    Text("Purchase dates and replacement eligibility depend on your organization's inventory system. The community edition does not query Apple Business Manager or other private inventory services.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
