import Foundation
import AppKit

enum SupportService {
    static func openPortal() {
        guard let url = URL(string: CommunityBranding.supportURL),
              url.scheme == "https", url.host != nil else { return }
        NSWorkspace.shared.open(url)
    }
    static func emailSupport() {
        guard !CommunityBranding.supportEmail.isEmpty,
              let encoded = CommunityBranding.supportEmail.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed),
              let url = URL(string: "mailto:" + encoded) else { return }
        NSWorkspace.shared.open(url)
    }
    static func openHelp() {
        guard let url = Bundle.main.url(forResource: "CommunityHelp", withExtension: "html") else { return }
        NSWorkspace.shared.open(url)
    }
}
