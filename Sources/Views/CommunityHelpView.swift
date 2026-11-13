import SwiftUI

// Bundled, native documentation. Both the sidebar and Help menu use SupportService.openHelp().
struct CommunityHelpView: View {
    private struct HelpTopic: Identifiable {
        let id: String
        let title: String
        let symbol: String
        let sections: [(String, String)]
    }

    private let topics: [HelpTopic] = [
        .init(id: "welcome", title: "Getting Started", symbol: "house", sections: [
            ("Welcome to My Mac Status", "My Mac Status Community Edition helps you understand your Mac’s health, hardware, battery, storage, security, and update readiness in one place. Most information comes directly from your Mac. Optional management connections provide additional inventory and replacement-planning information."),
            ("Navigation", "Choose a section in the sidebar to explore your Mac. Use the refresh button to update local information. Some checks, such as provider lookups, home-folder scans, and update readiness, run only when you request them."),
            ("Privacy and safety", "Diagnostics and update readiness checks are informational and read-only. Checking for updates does not download or install macOS. A home-folder scan does not remove files. Provider credentials are stored in your macOS Keychain.")
        ]),
        .init(id: "features", title: "Your Mac & Features", symbol: "macbook", sections: [
            ("Overview", "See a quick summary of your Mac and its current health information."),
            ("Device Insights", "Explore local hardware and operating-system information reported by macOS."),
            ("Health & Security", "Review local health and security indicators, including encryption and system protections. A local check is not an enterprise compliance certification."),
            ("Battery", "Review battery status and health information when supported by your Mac."),
            ("Storage", "View total and available storage. Available storage can include space macOS expects to reclaim. Scan your home folder to find large items; some protected locations may be excluded. No files are deleted."),
            ("Mac Details", "See device identity, open Apple’s coverage information, and check an estimated replacement date when inventory data is available."),
            ("Diagnostics", "Review local diagnostic information to help investigate common issues. These checks do not automatically repair your Mac.")
        ]),
        .init(id: "connections", title: "Optional Connections", symbol: "network", sections: [
            ("Open connection settings", "Choose Settings & Connections in the sidebar, or open My Mac Status → Settings (⌘,). Select the Connections tab."),
            ("Jamf Pro", "Select Jamf Pro, enter your organization’s API base URL, client ID, and client secret, then save and test the connection. Use a least-privilege API client with appropriate computer read access."),
            ("Iru / Kandji", "Select Iru / Kandji and provide the organization-specific API connection details requested by the app. Save and use Test Connection to verify access."),
            ("Apple Business Manager", "Select Apple Business Manager and provide the API credentials requested by the app, including the signing key where applicable. Save and test the connection. ABM Date Added can be used for replacement planning."),
            ("Keychain access", "Credentials are stored in your login Keychain. macOS may ask you to authorize access, especially after changing an app’s signing identity. Only approve access when you recognize the application. Existing credential import and consolidation actions are optional and user-initiated."),
            ("No connection required", "The local health, battery, storage, and update-readiness features work without connecting any management provider.")
        ]),
        .init(id: "lifecycle", title: "Replacement Planning", symbol: "calendar.badge.clock", sections: [
            ("Set your lifecycle", "Open Settings & Connections → Lifecycle. Choose the number of years used for replacement estimates and, if helpful, enter a replacement-policy URL."),
            ("Check a replacement date", "Open Mac Details and select Check Date. When available, Apple Business Manager’s Device Added date is preferred; supported management inventory data may provide a fallback."),
            ("Understand the estimate", "The estimated replacement date is calculated from the available device date and your selected lifecycle. It is a planning estimate, not a confirmed purchase date, warranty expiration, or replacement approval."),
            ("Missing information", "If a date cannot be found, check your provider connection and permissions. The app should not invent a replacement date when the underlying inventory record is unavailable.")
        ]),
        .init(id: "updates", title: "macOS Update Intelligence", symbol: "arrow.triangle.2.circlepath", sections: [
            ("Check for updates", "Open Health & Security and select Check for Updates in macOS Update Intelligence. The app performs a read-only local readiness check."),
            ("Availability", "Availability describes updates currently offered to this Mac. ‘No updates available right now’ does not necessarily mean this Mac has the latest public macOS release."),
            ("Readiness", "Readiness highlights local factors that may affect updating, such as available storage and whether your Mac is connected to power. A check cannot rule out every possible issue or organization policy."),
            ("Recommendation", "The recommendation summarizes what the current findings suggest. Expand ‘Why am I seeing this?’ for supporting details. Use Open Software Update to review Apple’s update interface before making a decision."),
            ("Managed Macs", "Your organization may defer or control updates. Follow your organization’s update policy when it differs from general guidance.")
        ]),
        .init(id: "troubleshooting", title: "Troubleshooting", symbol: "wrench.and.screwdriver", sections: [
            ("Information looks out of date", "Refresh local information, then rerun any manual check. Some results update only when you select their check button."),
            ("A provider connection fails", "Verify the service URL, credentials, network access, and API permissions. Select Test Connection in Settings & Connections. A provider outage or missing device record may also prevent a lookup."),
            ("Keychain authorization appears", "Confirm that you launched the expected app. If macOS requests Keychain access, use the authorization controls provided by macOS. Consistent code signing helps preserve previously granted access. Do not delete saved credentials as a first troubleshooting step."),
            ("Replacement date is unavailable", "Confirm the Mac exists in the selected provider inventory and that the account can read its record. Check the Lifecycle settings and try Check Date again."),
            ("Update results seem unexpected", "Open System Settings → General → Software Update to compare what macOS currently offers. Readiness checks are advisory, and managed update deferrals may affect availability."),
            ("Storage numbers differ", "Available storage includes potentially reclaimable capacity and can change as macOS manages disk space. Different macOS tools may report slightly different measurements."),
            ("Need more assistance?", "If your Mac is managed by an organization, contact your IT support team. Otherwise, use the app’s available support options or Apple’s built-in macOS help.")
        ])
    ]

    @State private var selected = "welcome"

    private var topicWindowTitle: String { "Help" }

    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                ForEach(topics) { topic in
                    Label(topic.title, systemImage: topic.symbol)
                        .tag(topic.id)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Help")
            .navigationSplitViewColumnWidth(min: 250, ideal: 270, max: 310)
        } detail: {
            ScrollView {
                if let topic = topics.first(where: { $0.id == selected }) {
                    VStack(alignment: .leading, spacing: 17) {
                        if ManagedConfiguration.brandingEnabled { ManagedBrandImage(width: 165, height: 44) }
                        Label(topic.title, systemImage: topic.symbol)
                            .font(.system(size: 27, weight: .bold))
                            .padding(.bottom, 2)
                        ForEach(Array(topic.sections.enumerated()), id: \.offset) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.element.0)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(item.element.1)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary.opacity(0.82))
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                        Divider()
                        Text("My Mac Status Community Edition • v2.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: 740, alignment: .leading)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(topicWindowTitle)
        }
        .frame(minWidth: 850, minHeight: 540)
    }
}
