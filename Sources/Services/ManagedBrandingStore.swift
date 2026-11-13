import SwiftUI
import AppKit
import CryptoKit

@MainActor final class ManagedBrandingStore: ObservableObject {
    static let shared = ManagedBrandingStore()
    @Published private(set) var lightImage: NSImage?
    @Published private(set) var darkImage: NSImage?
    private let maximumBytes = 2_000_000
    private var loaded = false

    func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard ManagedConfiguration.brandingEnabled else { return }
        if let encoded = ManagedConfiguration.brandingImageBase64,
           encoded.count < 2_700_000,
           let data = Data(base64Encoded: encoded), let image = decode(data) {
            lightImage = image; darkImage = image
        }
        let fallback = ManagedConfiguration.brandingImageURL
        load(ManagedConfiguration.brandingImageURLLight ?? fallback, dark: false)
        load(ManagedConfiguration.brandingImageURLDark ?? fallback, dark: true)
    }

    func image(dark: Bool) -> NSImage? {
        guard ManagedConfiguration.brandingEnabled else { return nil }
        return dark ? (darkImage ?? lightImage) : (lightImage ?? darkImage)
    }

    private func decode(_ data: Data) -> NSImage? {
        guard data.count <= maximumBytes, data.count > 8,
              let bitmap = NSBitmapImageRep(data: data),
              bitmap.pixelsWide > 0, bitmap.pixelsHigh > 0,
              bitmap.pixelsWide <= 4096, bitmap.pixelsHigh <= 4096 else { return nil }
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        return image
    }

    private func load(_ url: URL?, dark: Bool) {
        guard let url, url.scheme == "https", url.user == nil, url.password == nil else { return }
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyMacStatus/ManagedBranding", isDirectory: true)
        let path = directory.appendingPathComponent(hash + ".image")
        if let data = try? Data(contentsOf: path), let image = decode(data) {
            if dark { darkImage = image } else { lightImage = image }
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Do not attach provider credentials, cookies, device identifiers or authorization headers.
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        let session = URLSession(configuration: configuration)
        Task {
            defer { session.invalidateAndCancel() }
            guard let (data, response) = try? await session.data(for: request),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  http.url?.scheme == "https", data.count <= maximumBytes,
                  let image = decode(data) else { return }
            if dark { darkImage = image } else { lightImage = image }
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: path, options: .atomic)
        }
    }
}

struct ManagedBrandImage: View {
    @ObservedObject private var store = ManagedBrandingStore.shared
    @Environment(\.colorScheme) private var colorScheme
    var width: CGFloat = CGFloat(ManagedConfiguration.brandingImageWidth)
    var height: CGFloat = CGFloat(ManagedConfiguration.brandingImageHeight)
    var body: some View {
        Group {
            if let image = store.image(dark: colorScheme == .dark) {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Label(CommunityBranding.name, systemImage: "laptopcomputer")
                    .font(.headline).foregroundStyle(CompanionStyle.green)
            }
        }
        .frame(maxWidth: width, maxHeight: height)
        .accessibilityLabel("Organization branding")
        .onAppear { store.loadIfNeeded() }
    }
}
