import SwiftUI
import AppKit

struct MacHealthView: View {
    @EnvironmentObject private var model: CompanionModel
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Mac's health").font(.title3.weight(.semibold))
                    Text("Check key settings and protection on your Mac.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(status: model.macHealth.summary)
            }
            if model.macHealth.isScanning {
                InfoPanel {
                    HStack(spacing: 12) {
                        ProgressView().controlSize(.small)
                        Text("Checking device health… This may take a moment.")
                    }
                }
            }
            if let date = model.macHealth.checkedAt {
                Text("Last checked: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(model.macHealth.checks) { item in
                    InfoPanel {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.symbol)
                                .font(.title3)
                                .foregroundStyle(color(item.severity))
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(friendlyTitle(item))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 4)
                                    if item.id == "updates" {
                                        Button("Open Software Update") {
                                            if let url = URL(string: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension") {
                                                NSWorkspace.shared.open(url)
                                            } else {
                                                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                                            }
                                        }
                                        .font(.caption.weight(.medium))
                                        .controlSize(.small)
                                        .fixedSize()
                                        .help("Open System Settings → General → Software Update")
                                    }
                                }
                                Text(item.id == "updates" && item.value == "No updates offered" ? "Your Mac is up to date" : item.value).font(.headline)
                                Label(label(item.severity), systemImage: icon(item.severity))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(color(item.severity))
                                Text(friendlyDetail(item)).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                    }
                }
            }
            if model.macHealth.checkedAt == nil && !model.macHealth.isScanning {
                InfoPanel {
                    Text("Select Refresh to run Mac Health checks.").foregroundStyle(.secondary)
                }
            }
            InfoPanel {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundStyle(CompanionStyle.green)
                    Text("Some information may not be available during a scan. Refresh to check again.")
                        .font(.callout)
                }
            }
        }
    }

    private func friendlyTitle(_ item: MacHealthCheck) -> String {
        switch item.id {
        case "filevault": return "Disk Encryption"
        case "sip": return "System Protection"
        case "mdm": return "Device Management"
        case "mdm": return "Management Software"
        default: return item.title
        }
    }
    private func friendlyDetail(_ item: MacHealthCheck) -> String {
        if item.id == "mdm" && item.severity == .healthy { return "your organization’s device management software is installed." }
        if item.id == "filevault" && item.severity == .healthy { return "Your Mac’s storage is protected with encryption." }
        if item.id == "sip" && item.severity == .healthy { return "Your Mac’s built-in system protection is enabled." }
        if item.id == "updates" {
            return item.detail.components(separatedBy: "\n").filter { line in
                line.hasPrefix("Installed build:") || line.hasPrefix("Available build:") ||
                (!line.localizedCaseInsensitiveContains("MDM") && !line.localizedCaseInsensitiveContains("compliance") && !line.localizedCaseInsensitiveContains("deferral"))
            }.joined(separator: "\n")
        }
        return item.detail
    }

    private func label(_ severity: CheckSeverity) -> String {
        switch severity {
        case .healthy: return "Healthy"
        case .needsAttention: return "Needs Attention"
        case .unhealthy: return "Unhealthy"
        case .unableToVerify: return "Information Unavailable"
        }
    }
    private func icon(_ severity: CheckSeverity) -> String {
        switch severity {
        case .healthy: return "checkmark.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unableToVerify: return "questionmark.circle.fill"
        }
    }
    private func color(_ severity: CheckSeverity) -> Color {
        switch severity {
        case .healthy: return CompanionStyle.green
        case .needsAttention: return .orange
        case .unhealthy: return .red
        case .unableToVerify: return .secondary
        }
    }
}
