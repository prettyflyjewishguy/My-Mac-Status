import SwiftUI

struct CompanionRootView: View {
    @EnvironmentObject private var model: CompanionModel
    private var selected: CompanionPage { model.selection ?? .dashboard }
    var body: some View {
        NavigationSplitView {
            List(selection: $model.selection) {
                Section("Your Mac") {
                    ForEach(CompanionPage.allCases) { page in
                        Label(page.rawValue, systemImage: page.symbol).tag(page)
                    }
                }
                Section("Support") {
                    Button { SupportService.openHelp() } label: {
                        Label("Help & Documentation", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                    }
                    if !CommunityBranding.supportURL.isEmpty {
                        Button { SupportService.openPortal() } label: {
                            Label("Open Support Portal", systemImage: "lifepreserver")
                                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 205, ideal: 235, max: 290)
        } detail: {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PageHeader(title: selected.rawValue, subtitle: CommunityBranding.subtitle)
                        Group {
                            switch selected {
                            case .dashboard: DashboardView()
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
                ToolbarItem(placement: .primaryAction) {
                    Button { model.refresh() } label: {
                        Label("Refresh Local Information", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.loading)
                    .help("Refresh device and battery information")
                }
            }
        }
        .frame(minWidth: 850, idealWidth: 1100, minHeight: 600, idealHeight: 720)
        .onAppear { if model.lastRefresh == nil && !model.loading { model.refresh() } }
    }
}
