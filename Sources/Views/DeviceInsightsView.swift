import SwiftUI

struct DeviceInsightsView: View {
    @EnvironmentObject private var model: CompanionModel
    private var recommendations: [CommunityRecommendation] {
        CommunityHealthPolicy.recommendations(checks: model.macHealth.checks, expectation: model.managementExpectation)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Insights").font(.title2.bold())
            Text("A current snapshot of your Mac. Management status is separate from device health.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                StatusSurface(CompanionStyle.StatusTone(health: model.macHealth.dashboardSummary)) {
                    Label("Mac Health: \(model.macHealth.dashboardSummary.rawValue)", systemImage: "heart.text.square")
                        .foregroundStyle(CompanionStyle.StatusTone(health: model.macHealth.dashboardSummary).color)
                }
                StatusSurface(.informational) {
                    Label("Device Management: \(CommunityHealthPolicy.managementMessage(checks: model.macHealth.checks, expectation: model.managementExpectation))", systemImage: "laptopcomputer.and.arrow.down")
                        .foregroundStyle(CompanionStyle.StatusTone.informational.color)
                }
                InfoPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Management expectations", selection: $model.managementExpectation) {
                            ForEach(ManagementExpectation.allCases) { option in Text(option.rawValue).tag(option) }
                        }
                        .pickerStyle(.menu)
                        Text("Automatic and Personal Mac never require MDM enrollment. Select Organization-managed only if your organization requires it.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Suggested Next Steps").font(.headline)
            if recommendations.isEmpty {
                StatusSurface(.healthy) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("You're all set!", systemImage: "checkmark.circle.fill")
                        Text("No action is needed based on the checks completed so far.").foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(recommendations) { item in
                    StatusSurface(.warning) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline)
                            Text(item.guidance).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text("Recommendations reflect current checks only. Diagnostic history does not affect current health.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
