import SwiftUI
import AppKit

struct AppleCareLifecycleView: View {
    @EnvironmentObject private var model: CompanionModel
    private var result: CommunityLifecycleResult? { model.lifecycle.data }
    private func replacementField(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
    // Presentation only: preserve the raw date values returned by the lifecycle service.
    private func displayReplacementDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Information unavailable" }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.calendar = Calendar(identifier: .gregorian)
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        parser.isLenient = false
        guard let date = parser.date(from: raw) else { return raw }
        let display = DateFormatter()
        display.locale = Locale.current
        display.calendar = Calendar(identifier: .gregorian)
        display.timeZone = TimeZone(secondsFromGMT: 0)
        display.dateStyle = .long
        display.timeStyle = .none
        return display.string(from: date)
    }
    // Alpha 2 Increment 2: presentation-only Device Profile Dashboard.
    // All device, lifecycle, and coverage values and actions remain unchanged.
    private var hasReplacementRecord: Bool { result?.found == true }

    private var replacementStatus: String {
        if model.lifecycle.loading { return "Checking replacement information" }
        if model.lifecycle.error != nil { return "Unable to retrieve information" }
        if let result, result.found { return result.lifecycleStatus ?? "Information available" }
        return "Replacement date unavailable"
    }

    private var replacementTone: CompanionStyle.StatusTone {
        model.lifecycle.error == nil ? .informational : .warning
    }

    private var appleCareCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AppleCare & Warranty").font(.headline)
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(CompanionStyle.statusText(.informational))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Coverage Status").font(.subheadline.weight(.medium))
                    Text("Not checked")
                        .font(.subheadline)
                        .foregroundStyle(CompanionStyle.statusText(.informational))
                    Text("Check with Apple for current warranty and AppleCare details.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            // Fix 6: identical two-row action footer in both cards.
            // Reserve the secondary row even when no secondary action exists.
            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    if let url = URL(string: "https://checkcoverage.apple.com/") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Check Coverage", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Color.clear.frame(height: 16).accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
    }

    private var replacementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replacement Planning").font(.headline)
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(CompanionStyle.statusText(replacementTone))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Estimated Replacement Date").font(.subheadline.weight(.medium))
                    Text(replacementStatus)
                        .font(.subheadline)
                        .foregroundStyle(CompanionStyle.statusText(replacementTone))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if model.lifecycle.loading {
                ProgressView("Checking replacement information…").font(.caption)
            }
            if let error = model.lifecycle.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(CompanionStyle.statusText(.warning))
            }
            if let result, result.found {
                VStack(alignment: .leading, spacing: 8) {
                    replacementField(result.dateLabel, displayReplacementDate(result.dateAdded))
                    replacementField("Estimated Replacement", displayReplacementDate(result.projectedReplacementDate))
                    replacementField("Status", result.lifecycleStatus ?? "Information unavailable")
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Button { model.refreshLifecycle() } label: {
                    Label("Check Date", systemImage: "arrow.clockwise")
                }
                .disabled(model.lifecycle.loading)
                .buttonStyle(.bordered)
                .controlSize(.regular)
                ZStack(alignment: .trailing) {
                    Color.clear
                    if !hasReplacementRecord && !model.lifecycle.loading {
                        SettingsLink {
                            Text("Configure Connections")
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(CompanionStyle.blue)
                        .accessibilityLabel("Configure Connections in Settings")
                    }
                }
                .frame(height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Device identity: one compact, readable profile rather than two metric tiles.
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 31))
                    .foregroundStyle(CompanionStyle.blue)
                    .frame(width: 58, height: 58)
                    .background(CompanionStyle.tintedCard(.blue), in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.device.computerName)
                        .font(.title2.weight(.semibold))
                        .textSelection(.enabled)
                    Text("\(model.device.model)  ·  macOS \(model.device.macOS)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text("Serial Number:").foregroundStyle(.secondary)
                        Text(model.device.serial).textSelection(.enabled)
                    }
                    .font(.caption)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.tintedCard(.blue), in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
            .overlay(RoundedRectangle(cornerRadius: CompanionStyle.radius).strokeBorder(CompanionStyle.blue.opacity(0.12)))

            // Alpha 2 Increment 2 Fix 4: equal-height, responsive feature cards.
            // ViewThatFits stacks the cards when two minimum-width cards cannot fit.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    appleCareCard.frame(minWidth: 300, maxWidth: .infinity)
                    replacementCard.frame(minWidth: 300, maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: 14) {
                    appleCareCard
                    replacementCard
                }
            }
            if let updated = model.lifecycle.lastUpdated {
                Text("Replacement information last checked: \(updated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
