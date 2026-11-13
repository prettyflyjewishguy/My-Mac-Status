import SwiftUI

/// Built-in About window, available from the My Mac Status application menu.
struct AboutMyMacStatusView: View {
    private var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }
    private var version: String { info["CFBundleShortVersionString"] as? String ?? "Unknown" }
    private var build: String { info["CFBundleVersion"] as? String ?? "Unknown" }
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().interpolation(.high).frame(width: 80, height: 80)
                .accessibilityHidden(true)
            if ManagedConfiguration.brandingEnabled {
                ManagedBrandImage(width: 200, height: 65)
            }
            Text("My Mac Status").font(.title2.bold())
            Text("Community Edition").foregroundStyle(.secondary)
            Text("Version \(version) (Build \(build))")
                .font(.callout.monospacedDigit())
            Text("Alpha 2 • Release Candidate 1")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Local Mac health, update readiness, and optional device inventory connections.")
                .multilineTextAlignment(.center)
                .font(.callout).foregroundStyle(.secondary)
            if !ManagedConfiguration.hideHelpAndDocumentation {
                Button("Help & Documentation") { SupportService.openHelp() }
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(width: 400)
    }
}
