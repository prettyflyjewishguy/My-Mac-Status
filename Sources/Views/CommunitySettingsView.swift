import SwiftUI

struct CommunitySettingsView: View {
    @AppStorage("lifecycle.years") private var lifecycleYears = 4
    @AppStorage("lifecycle.policyURL") private var policyURL = ""

    var body: some View {
        Group {
        if ManagedConfiguration.hideSettingsAndConnections {
            VStack(spacing: 12) {
                Label("Managed by your organization", systemImage: "lock.shield")
                    .font(.headline)
                Text("Settings and connections are managed by your administrator.")
                    .foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
        TabView {
            ConnectionsView()
                .padding(20)
                .tabItem { Label("Connections", systemImage: "network") }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Replacement estimates")
                        .font(.headline)
                    Text("Choose the lifecycle used to estimate when a Mac may be due for replacement. Estimates are informational.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Replacement lifecycle")
                                .font(.body.weight(.medium))
                            Spacer(minLength: 8)
                            Stepper("\(lifecycleYears) years", value: $lifecycleYears, in: 1...15)
                                .fixedSize()
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Replacement policy URL (optional)")
                                .font(.body.weight(.medium))
                            TextField("https://example.com/replacement-policy", text: $policyURL)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Replacement policy URL")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Label("How estimates work", systemImage: "info.circle")
                            .font(.subheadline.weight(.semibold))
                        Text("The app prefers ABM's date-added value when available. MDM dates are used only as a fallback and are labeled by source. These are not purchase dates.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)
                    Spacer(minLength: 0)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tabItem { Label("Lifecycle", systemImage: "calendar") }
        }
        }
        }
        .frame(minWidth: 740, minHeight: 540)
    }
}
