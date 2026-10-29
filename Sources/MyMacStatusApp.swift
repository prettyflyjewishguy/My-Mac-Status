import SwiftUI
import AppKit

@main struct MyMacStatusApp: App {
    @StateObject private var model = CompanionModel()
    var body: some Scene {
        WindowGroup {
            CompanionRootView().environmentObject(model)
        }
        .commands {
            // File menu: actions available in this build, with familiar macOS shortcuts.
            CommandGroup(replacing: .newItem) {
                Button("Show Dashboard") { model.selection = .dashboard }
                    .keyboardShortcut("1", modifiers: [.command])
                Button("Show Mac Health") { model.selection = .macHealth }
                    .keyboardShortcut("2", modifiers: [.command])
                Button("Show Battery Health") { model.selection = .batteryHealth }
                    .keyboardShortcut("3", modifiers: [.command])
                Button("Show Storage") { model.selection = .storage }
                    .keyboardShortcut("4", modifiers: [.command])
                Button("Show Mac Details") { model.selection = .appleCare }
                    .keyboardShortcut("5", modifiers: [.command])
                Button("Show Diagnostics & Repair") { model.selection = .diagnostics }
                    .keyboardShortcut("6", modifiers: [.command])
                Divider()
                Button("Refresh Local Information") { model.refresh() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(model.loading)
            }
            CommandGroup(replacing: .help) {
                Button("My Mac Status Help") { SupportService.openHelp() }
                    .keyboardShortcut("?", modifiers: [.command])
                Divider()
                if !CommunityBranding.supportURL.isEmpty {
                    Button("Open Support Portal") { SupportService.openPortal() }
                }
                if !CommunityBranding.supportEmail.isEmpty {
                    Button("Email Support") { SupportService.emailSupport() }
                }
            }
        }
    }
}
