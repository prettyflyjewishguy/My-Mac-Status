import SwiftUI

// Alpha 5.3: presentation-only dashboard. All values come from the existing model.
struct DashboardView: View {
    @EnvironmentObject private var model: CompanionModel
    private var device: DeviceInfo { model.device }
    private var battery: BatterySnapshot { model.battery }
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private func size(_ bytes: Int64?) -> String {
        guard let bytes else { return "Information unavailable" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    private var updateCheck: MacHealthCheck? { model.macHealth.checks.first(where: { $0.id == "updates" }) }
    private var attentionCount: Int { model.macHealth.checks.filter { $0.severity == .needsAttention || $0.severity == .unhealthy }.count }
    private var unknownCount: Int { model.macHealth.checks.filter { $0.severity == .unableToVerify }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Mac at a glance").font(.title3.weight(.semibold))
                    Text("A quick overview of your device, protection, and everyday essentials.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if let date = model.macHealth.checkedAt {
                    Text("Checked \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 15) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 35)).foregroundStyle(CompanionStyle.green)
                    .frame(width: 56, height: 56)
                    .background(CompanionStyle.green.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(device.computerName).font(.title2.bold()).textSelection(.enabled)
                    Text("\(device.model)  ·  \(device.macOS)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                StatusPill(status: dashboardStatus)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

            Text("Quick actions & status").font(.headline)
            LazyVGrid(columns: columns, spacing: 12) {
                tile("Mac Health", value: healthText, detail: healthDetail,
                     symbol: "heart.text.square.fill", tint: dashboardStatus.color, page: .macHealth)
                tile("Battery", value: battery.charge.map { "\($0)% charged" } ?? "Unavailable",
                     detail: "Condition: \(battery.condition)", symbol: "battery.100percent",
                     tint: BatteryPresentation.color(battery.condition), page: .batteryHealth)
                tile("Storage", value: size(device.freeBytes) + " free",
                     detail: "of \(size(device.totalBytes)) total", symbol: "internaldrive.fill",
                     tint: .blue, page: .storage)
                tile("Mac Details", value: "Device details", detail: "View hardware information",
                     symbol: "checkmark.shield.fill", tint: .purple, page: .appleCare)
            }

            HStack(spacing: 12) {
                Image(systemName: updateCheck?.severity == .needsAttention ? "arrow.down.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2).foregroundStyle(updateCheck?.severity == .needsAttention ? .orange : .blue)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Software Updates").font(.subheadline.weight(.semibold))
                    Text(updateCheck?.value == "No updates offered" ? "Your Mac is up to date" : (updateCheck?.value ?? "Not yet checked"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    if let detail = updateCheck?.detail {
                        ForEach(detail.components(separatedBy: "\n").filter {
                            $0.hasPrefix("Installed build:") || $0.hasPrefix("Available build:")
                        }, id: \.self) { line in
                            Text(line).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Button("View Updates") { model.selection = .macHealth }
                    .controlSize(.small)
            }
            .padding(16)
            .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))

            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill").foregroundStyle(CompanionStyle.green)
                Text("Select any card to explore your Mac’s health, storage, and more.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 3)
        }
    }

    private var dashboardStatus: HealthStatus { model.macHealth.dashboardSummary }
    private var healthText: String { dashboardStatus.rawValue }
    private var healthDetail: String {
        guard model.macHealth.checkedAt != nil else { return "Refresh to check your Mac" }
        if dashboardStatus == .unhealthy || dashboardStatus == .needsAttention { return "Review your Mac’s health details" }
        if dashboardStatus == .unableToVerify { return "Some health information is unavailable" }
        if updateCheck?.severity == .needsAttention { return "Software update available" }
        return "Your Mac looks good"
    }
    private func tile(_ title: String, value: String, detail: String,
                      symbol: String, tint: Color, page: CompanionPage) -> some View {
        Button { model.selection = page } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: symbol)
                    .font(.title2).foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    Text(value).font(.headline).foregroundStyle(.primary).lineLimit(2)
                    Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(15)
            .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(tint.opacity(0.12)))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .help("Open \(title)")
        .accessibilityLabel("\(title): \(value). \(detail). Open details")
    }
}
