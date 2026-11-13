import SwiftUI

struct CompanionRootView: View {
    @EnvironmentObject private var model: CompanionModel
    @ObservedObject private var theme = ManagedThemeManager.shared
    @Environment(\.openSettings) private var openSettings
    private var selected: CompanionPage { model.selection ?? .dashboard }
    // A native List(selection:) paints the system-blue selection background on macOS,
    // even when .tint is set. Explicit selection rows honor managed colors instead.
    private func sidebarPageRow(_ page: CompanionPage) -> some View {
        let isSelected = selected == page
        return Button {
            model.selection = page
        } label: {
            HStack(spacing: 6) {
                Image(systemName: page.symbol)
                    .foregroundStyle(isSelected ? Color.white : theme.accent)
                Text(page.rawValue)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
            }
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.selection)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Your Mac") {
                    ForEach(CompanionPage.allCases.filter { $0 != .diagnostics }) { page in
                        sidebarPageRow(page)
                    }
                }
                Section("Troubleshooting") {
                    sidebarPageRow(.diagnostics)
                }
                if !ManagedConfiguration.hideSettingsAndConnections {
                Section("Configuration") {
                    Button { openSettings() } label: {
                        Label("Settings & Connections", systemImage: "gearshape")
                            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                }
                if !ManagedConfiguration.hideHelpAndDocumentation || !CommunityBranding.supportURL.isEmpty {
                Section("Support") {
                    if !ManagedConfiguration.hideHelpAndDocumentation {
                    Button { SupportService.openHelp() } label: {
                        Label("Help & Documentation", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    }
                    if !CommunityBranding.supportURL.isEmpty {
                        Button { SupportService.openPortal() } label: {
                            Label("Open Support Portal", systemImage: "lifepreserver")
                                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                }
            }
            .listStyle(.sidebar)
            .onMoveCommand { direction in
                let pages = CompanionPage.allCases
                guard let index = pages.firstIndex(of: selected) else { return }
                switch direction {
                case .up where index > 0: model.selection = pages[index - 1]
                case .down where index < pages.count - 1: model.selection = pages[index + 1]
                default: break
                }
            }
            .navigationSplitViewColumnWidth(min: 205, ideal: 235, max: 290)
        } detail: {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PageHeader(title: selected.rawValue, subtitle: CommunityBranding.subtitle)
                        Group {
                            switch selected {
                            case .dashboard: DashboardView()
                            case .insights: DeviceInsightsView()
                            case .batteryHealth: BatteryHealthView()
                            case .macHealth: MacHealthView()
                            case .storage: StorageView()
                            case .appleCare: AppleCareLifecycleView()
                            case .diagnostics: DiagnosticsRepairView()
                            }
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                HStack(spacing: 9) {
                    Circle().fill(model.loading ? Color.orange : (model.lastRefresh == nil ? Color.secondary : CompanionStyle.green))
                        .frame(width: 9, height: 9)
                    Text(model.loading ? "Refreshing local information…" : "Local device information")
                    Spacer()
                    if let message = model.refreshMessage {
                        Text(message).foregroundStyle(.orange)
                    }
                    Text(model.lastRefresh.map { "Last refreshed: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Not yet refreshed")
                    if !CommunityBranding.supportURL.isEmpty {
                        Button("Get Help") { SupportService.openPortal() }.buttonStyle(.link)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 26).padding(.vertical, 12)
            }
            .onChange(of: model.selection) { _, page in
                switch page {
                case .macHealth: model.refreshHealthIfStale()
                case .batteryHealth: model.refreshBatteryIfStale()
                default: break
                }
            }
            .toolbar {
                if !ManagedConfiguration.hideSettingsAndConnections {
                ToolbarItem(placement: .primaryAction) {
                    Button { openSettings() } label: { Label("Settings & Connections", systemImage: "gearshape") }
                        .help("Configure Jamf Pro, Iru/Kandji, Apple Business Manager, and lifecycle")
                }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { model.refresh() } label: {
                        Label("Refresh Local Information", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.loading)
                    .help("Refresh device and battery information")
                }
            }
        }
        .tint(theme.accent)
        .frame(minWidth: 850, idealWidth: 1100, minHeight: 600, idealHeight: 720)
        .onAppear { if model.lastRefresh == nil && !model.loading { model.refresh() } }
    }
}
