import SwiftUI
import AppKit

enum CommunityBranding {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CommunityBrandName") as? String ?? "My Mac Status"
    static let subtitle = Bundle.main.object(forInfoDictionaryKey: "CommunityBrandSubtitle") as? String ?? "Device Health"
    static let supportEmail = Bundle.main.object(forInfoDictionaryKey: "CommunitySupportEmail") as? String ?? ""
    static let supportURL = Bundle.main.object(forInfoDictionaryKey: "CommunitySupportURL") as? String ?? ""
}

enum CompanionStyle {
    static let green = Color.accentColor
    static let card = Color.primary.opacity(0.045)
    static let radius: CGFloat = 13
}

struct CompanionLogo: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "BrandLogo", withExtension: "png"),
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
    var color: Color = CompanionStyle.green
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
        .background(CompanionStyle.card, in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
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
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.card, in: RoundedRectangle(cornerRadius: CompanionStyle.radius))
    }
}
