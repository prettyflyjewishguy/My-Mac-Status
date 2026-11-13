import Foundation
import AppKit
import SwiftUI

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
    private static var helpWindow: NSWindow?

    static func openHelp() {
        guard !ManagedConfiguration.hideHelpAndDocumentation else {
            helpWindow?.orderOut(nil)
            return
        }
        if let helpWindow {
            helpWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1050, height: 740),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "My Mac Status Help"
        window.contentViewController = NSHostingController(rootView: CommunityHelpView())
        window.minSize = NSSize(width: 850, height: 540)
        window.center()
        window.isReleasedWhenClosed = false
        helpWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
