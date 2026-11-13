import SwiftUI
import AppKit

enum CommunityBranding {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CommunityBrandName") as? String ?? "My Mac Status"
    static let subtitle = Bundle.main.object(forInfoDictionaryKey: "CommunityBrandSubtitle") as? String ?? "Device Health"
    static let supportEmail = Bundle.main.object(forInfoDictionaryKey: "CommunitySupportEmail") as? String ?? ""
    static let supportURL = Bundle.main.object(forInfoDictionaryKey: "CommunitySupportURL") as? String ?? ""
}

enum CompanionStyle {
    static let green = Color.green
    static let card = Color.primary.opacity(0.045)
    // Presentation-only palette; status and management decisions remain in their existing models.
    static var blue: Color { ManagedThemeManager.shared.primary }
    static var teal: Color { ManagedThemeManager.shared.secondary }
    static let purple = Color.purple
    static let orange = Color.orange
    static func tintedCard(_ tint: Color) -> Color { tint.opacity(0.075) }
    // Semantic presentation tokens only. These do not classify or calculate device health.
    enum StatusTone {
        case healthy, warning, critical, informational, unavailable

        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .critical: return .red
            case .informational: return .blue
            case .unavailable: return .secondary
            }
        }
    }

    static func statusBackground(_ tone: StatusTone) -> Color {
        tone.color.opacity(0.085)
    }
    static func statusBorder(_ tone: StatusTone) -> Color {
        tone.color.opacity(0.14)
    }
    static func statusText(_ tone: StatusTone) -> Color { tone.color }
    static let radius: CGFloat = 13
}

struct CompanionLogo: View {
    var body: some View {
        Group {
            if ManagedConfiguration.brandingEnabled {
                ManagedBrandImage()
            } else if let url = Bundle.main.url(forResource: "BrandLogo", withExtension: "png"),
                      let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Label(CommunityBranding.name, systemImage: "laptopcomputer")
                    .font(.headline).foregroundStyle(CompanionStyle.green)
            }
        }
        .frame(width: 165, height: 58)
        .accessibilityLabel(CommunityBranding.name)
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 29, weight: .bold))
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                CompanionLogo()
            }
            Divider()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    var color: Color = CompanionStyle.blue
    var explanation: String? = nil
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(color).frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    if let explanation {
                        Image(systemName: "info.circle").font(.caption).foregroundStyle(.secondary)
                            .help(explanation).accessibilityLabel("About \(title): \(explanation)")
                    }
                }
                Text(value).font(.headline).lineLimit(2).textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .background(CompanionStyle.tintedCard(color), in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
        .overlay(RoundedRectangle(cornerRadius: CompanionStyle.radius).strokeBorder(color.opacity(0.11)))
    }
}

struct StatusPill: View {
    let status: HealthStatus
    var body: some View {
        Label(status.rawValue, systemImage: status.symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(status.color.opacity(0.10), in: Capsule())
    }
}

struct InfoPanel<Content: View>: View {
    var tint: Color = .clear
    let content: Content
    init(tint: Color = .clear, @ViewBuilder content: () -> Content) { self.tint = tint; self.content = content() }
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(tint == .clear ? CompanionStyle.card : CompanionStyle.tintedCard(tint), in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
            .overlay(RoundedRectangle(cornerRadius: CompanionStyle.radius).strokeBorder(tint.opacity(0.10)))
    }
}

// UI-only mapping. Severity is still computed exclusively by existing services/models.
extension CompanionStyle.StatusTone {
    init(severity: CheckSeverity) {
        switch severity {
        case .healthy: self = .healthy
        case .needsAttention: self = .warning
        case .unhealthy: self = .critical
        case .unableToVerify: self = .unavailable
        }
    }
    init(health: HealthStatus) {
        switch health {
        case .healthy: self = .healthy
        case .needsAttention: self = .warning
        case .unhealthy: self = .critical
        case .unableToVerify, .notEvaluated: self = .unavailable
        }
    }
}

struct StatusSurface<Content: View>: View {
    let tone: CompanionStyle.StatusTone
    let content: Content
    init(_ tone: CompanionStyle.StatusTone, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.statusBackground(tone), in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
            .overlay(RoundedRectangle(cornerRadius: CompanionStyle.radius)
                .strokeBorder(CompanionStyle.statusBorder(tone)))
    }
}
