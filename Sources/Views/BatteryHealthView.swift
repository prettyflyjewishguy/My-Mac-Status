import SwiftUI

enum BatteryPresentation {
    static func color(_ condition: String) -> Color {
        let lower = condition.lowercased()
        if lower.contains("service") || lower.contains("replace") || lower.contains("poor") { return .orange }
        if lower == "normal" || lower == "good" { return CompanionStyle.green }
        return .secondary
    }
    static func symbol(_ condition: String) -> String {
        let lower = condition.lowercased()
        if lower.contains("service") || lower.contains("replace") || lower.contains("poor") { return "exclamationmark.circle.fill" }
        if lower == "normal" || lower == "good" { return "checkmark.circle.fill" }
        return "questionmark.circle.fill"
    }
}

struct BatteryHealthView: View {
    @EnvironmentObject private var model: CompanionModel
    private var battery: BatterySnapshot { model.battery }
    private func value(_ number: Int?, suffix: String = "") -> String {
        number.map { "\($0)\(suffix)" } ?? "Unavailable"
    }
    private var batterySymbol: String {
        guard let charge = battery.charge else { return "battery.0percent" }
        switch charge {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            Text("Understand your battery's health and power status.").font(.title3.weight(.medium))
            Text("Readings are reported by macOS. Battery information refreshes when you open this page.").foregroundStyle(.secondary)
            if model.batteryRefreshing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Updating battery information…").foregroundStyle(.secondary)
                }.font(.caption)
            }
            if let error = battery.error {
                Label(error, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
            InfoPanel {
                HStack(spacing: 20) {
                    Image(systemName: batterySymbol).font(.system(size: 43, weight: .light))
                        .foregroundStyle(CompanionStyle.green).frame(width: 70)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(battery.headline).font(.system(size: 43, weight: .bold, design: .rounded))
                        Text("Current charge").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 6) {
                        Label(battery.condition, systemImage: BatteryPresentation.symbol(battery.condition))
                            .foregroundStyle(BatteryPresentation.color(battery.condition))
                            .font(.subheadline.weight(.semibold))
                        Text("Battery condition").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Battery Health").font(.headline)
            HStack(spacing: 12) {
                MetricCard(title: "Maximum Capacity", value: value(battery.maxCapacity, suffix: "%"), symbol: "gauge.with.dots.needle.67percent", explanation: "Current capacity compared with when the battery was new.")
                MetricCard(title: "Cycle Count", value: value(battery.cycles), symbol: "arrow.triangle.2.circlepath", explanation: "Cumulative use equivalent to 100% of battery capacity.")
            }
            HStack(spacing: 12) {
                MetricCard(title: "Battery Condition", value: battery.condition, symbol: BatteryPresentation.symbol(battery.condition), color: BatteryPresentation.color(battery.condition))
                MetricCard(title: "Adapter Wattage", value: battery.connected == false ? "Not connected" : value(battery.watts, suffix: " W"), symbol: "bolt.circle")
            }
            Text("Power Status").font(.headline)
            HStack(spacing: 12) {
                MetricCard(title: "AC Power", value: battery.connected.map { $0 ? "Connected" : "Disconnected" } ?? "Unavailable", symbol: "powerplug")
                MetricCard(title: "Charging", value: battery.charging.map { $0 ? "Charging" : "Not charging" } ?? "Unavailable", symbol: "bolt")
            }
            InfoPanel {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Understanding your battery")
                        .font(.headline)
                    Text("Maximum Capacity compares the battery's current charge capacity with its original capacity. Cycle Count reflects cumulative battery use, not the number of times you plugged in your Mac.")
                        .foregroundStyle(.secondary)
                    Text("macOS determines battery condition. If it reports a service warning or charging seems unusual, use Get help below.")
                        .foregroundStyle(.secondary)
                }
            }
            InfoPanel {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(CompanionStyle.green)
                        .accessibilityHidden(true)
                    Text(battery.advice)
                        .font(.callout)
                    Spacer(minLength: 12)
                    if !CommunityBranding.supportURL.isEmpty {
                    Button("Get help") { SupportService.openPortal() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                        .font(.callout.weight(.medium))
                        .accessibilityLabel("Get help from the support team")
                    }
                }
            }
        }
    }
}
