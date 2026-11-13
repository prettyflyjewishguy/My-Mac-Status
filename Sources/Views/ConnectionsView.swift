import SwiftUI
import UniformTypeIdentifiers
import CryptoKit

struct ConnectionsView: View {
    @State private var selected: ProviderKind = .jamf
    @State private var endpoint = ""
    @State private var token = ""
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var keyID = ""
    @State private var privateKey = ""
    @State private var hasCredential = false
    @State private var message = ""
    @State private var showLegacyAppleToken = false
    @State private var importingPEM = false
    @State private var showMigrationConfirmation = false
    @State private var showConsolidationConfirmation = false
    @State private var testingConnection = false
    @State private var testResult: String? = nil
    @State private var testSucceeded = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
            Text("Optional provider connections").font(.headline)
            Text("Your Mac works without an MDM connection. Connect a provider to look up this Mac's inventory record. Credentials stay in your user Keychain.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("Provider").font(.subheadline.weight(.medium))
                Picker("Provider", selection: $selected) {
                    ForEach(ProviderKind.allCases) { provider in Text(provider.rawValue).tag(provider) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .accessibilityLabel("Connection provider")
            }
            InfoPanel {
                VStack(alignment: .leading, spacing: 12) {
                    // Provider guidance belongs with the fields it describes.
                    Text(selected == .iru ? "Use the tenant API URL from Settings → Access and a read-only device API token." :
                         selected == .jamf ? "Use a dedicated Jamf Pro API Client with a least-privilege Read Computers role. Tokens are requested when needed." :
                         "Apple Business API uses a client ID, key ID, and signing key. Signed JWT authentication is available; existing access tokens remain supported.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if selected != .abm {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("API base URL").font(.subheadline.weight(.medium))
                            TextField("https://…", text: $endpoint)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("API base URL")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Apple Business API").font(.subheadline.weight(.medium))
                            Text("https://api-business.apple.com")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if selected == .jamf || selected == .abm {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Client ID").font(.subheadline.weight(.medium))
                            TextField("Client ID", text: $clientID).textFieldStyle(.roundedBorder)
                                .textContentType(.none)
                        }
                    }
                    if selected == .jamf {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Client Secret").font(.subheadline.weight(.medium))
                            SecureField("Leave blank to keep saved secret", text: $clientSecret)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else if selected == .abm {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Key ID").font(.subheadline.weight(.medium))
                            TextField("Key ID", text: $keyID).textFieldStyle(.roundedBorder)
                            Text("Private signing key (PEM)").font(.subheadline.weight(.medium))
                            HStack(spacing: 8) {
                                SecureField("Leave blank to keep saved key", text: $privateKey)
                                    .textFieldStyle(.roundedBorder)
                                Button("Import PEM…") { importingPEM = true }
                                    .buttonStyle(.bordered)
                            }
                            Text("Import a P-256 private key (.pem) from Apple Business Manager. The file is read locally and the key is saved to Keychain when you select Save Connection.")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Credentials are saved securely; authentication is verified when you check a device.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if selected == .iru {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("API token").font(.subheadline.weight(.medium))
                            SecureField("Leave blank to keep saved token", text: $token)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else if selected == .abm {
                        DisclosureGroup("Advanced / Legacy Authentication", isExpanded: $showLegacyAppleToken) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Existing OAuth access token (legacy)")
                                    .font(.subheadline.weight(.medium))
                                SecureField("Leave blank to keep saved token", text: $token)
                                    .textFieldStyle(.roundedBorder)
                                Text("Existing access tokens are supported while signed JWT exchange is being validated.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    HStack(spacing: 10) {
                        Button("Save Connection") {
                            ProviderSettings.setEndpoint(endpoint, for: selected)
                            let saved: Bool
                            switch selected {
                            case .jamf:
                                saved = (!clientID.isEmpty && !clientSecret.isEmpty)
                                    ? ProviderAuthentication.saveJamf(clientID: clientID, secret: clientSecret)
                                    : ProviderAuthentication.hasCredential(.jamf)
                            case .iru:
                                saved = token.isEmpty ? ProviderAuthentication.hasCredential(.iru)
                                    : { ProviderVerification.clear(.iru); return ProviderSettings.setCredential(token, for: .iru) }()
                            case .abm:
                                saved = (!clientID.isEmpty && !keyID.isEmpty && !privateKey.isEmpty)
                                    ? ProviderAuthentication.saveApple(clientID: clientID, keyID: keyID, privateKeyPEM: privateKey)
                                    : ProviderAuthentication.hasCredential(.abm)
                                if !token.isEmpty { ProviderVerification.clear(.abm); _ = ProviderSettings.setCredential(token, for: .abm) }
                            }
                            message = saved ? "Connection settings saved to this Mac." : "Enter the required credentials before saving."
                            loadSensitiveFields()
                            hasCredential = ProviderAuthentication.hasCredential(selected)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Remove Credential") {
                            let removed = ProviderAuthentication.remove(selected)
                            loadSensitiveFields()
                            hasCredential = ProviderAuthentication.hasCredential(selected)
                            message = removed ? "Saved credentials removed." : "Unable to remove all credentials from Keychain."
                        }
                        .buttonStyle(.bordered)
                        Button(testingConnection ? "Testing…" : "Test Connection") {
                            let provider = selected
                            testingConnection = true
                            testResult = nil
                            Task {
                                do {
                                    let date = try await ProviderConnectionTest.run(provider)
                                    if selected == provider {
                                        testSucceeded = true
                                        testResult = "Connected · Verified \(date.formatted(date: .abbreviated, time: .shortened))"
                                    }
                                } catch {
                                    if selected == provider {
                                        testSucceeded = false
                                        testResult = "Connection failed: \(error.localizedDescription)"
                                    }
                                }
                                testingConnection = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(testingConnection || !hasCredential)
                        Spacer(minLength: 6)
                    }
                    Button("Authorize Saved Credentials…") {
                        message = ProviderCredentials.authorizeSavedCredentials(for: selected)
                        hasCredential = ProviderAuthentication.hasCredential(selected)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .help("Explicitly authorize this provider's saved Keychain credentials. macOS may ask for permission here in Connections.")
                    Button("Consolidate Saved Credentials…") {
                        showConsolidationConfirmation = true
                    }
                    Button("Import Existing Keychain Credentials…") {
                        showMigrationConfirmation = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .help("Optional one-time import from an older version. Existing credentials will not be deleted.")
                    HStack(spacing: 7) {
                        Image(systemName: hasCredential ? "checkmark.circle.fill" : "info.circle")
                            .foregroundStyle(hasCredential ? Color.green : Color.secondary)
                        Text(hasCredential ? (ProviderVerification.verifiedAt(selected) != nil ? "Previously verified connection" : "Credential saved in Keychain · Not verified") : "No saved credential")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 9)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
                    if let testResult {
                        Label(testResult, systemImage: testSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(testSucceeded ? Color.green : Color.orange)
                    }
                    if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Text("Credentials are stored in your Mac's Keychain. If macOS needs permission, select Authorize Saved Credentials here. Check Date never requests Keychain authorization.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog("Consolidate saved credentials?", isPresented: $showConsolidationConfirmation) {
            Button("Consolidate Credentials") {
                message = ProviderCredentials.consolidateExisting(for: selected)
                hasCredential = ProviderAuthentication.hasCredential(selected)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This one-time action may ask permission to read existing Keychain entries. Your original credentials will remain intact. Normal replacement checks never consolidate credentials automatically.")
        }
        .confirmationDialog("Import existing credentials?", isPresented: $showMigrationConfirmation) {
            Button("Import Credentials") {
                message = ProviderCredentials.migrateLegacy(for: selected)
                hasCredential = ProviderAuthentication.hasCredential(selected)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This may require Keychain authorization. Original credentials will remain intact, and future device checks will not initiate migration.")
        }
        .onAppear(perform: load)
        .onChange(of: selected) { _, _ in load() }
        .fileImporter(isPresented: $importingPEM, allowedContentTypes: [.data, .plainText], allowsMultipleSelection: false) { result in
            switch result {
            case .failure:
                message = "Could not open the selected file."
            case .success(let urls):
                guard let url = urls.first else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                guard url.pathExtension.lowercased() == "pem",
                      let data = try? Data(contentsOf: url), data.count < 64_000,
                      let value = String(data: data, encoding: .utf8),
                      (try? P256.Signing.PrivateKey(pemRepresentation: value)) != nil else {
                    message = "Select a valid P-256 private signing key (.pem)."
                    return
                }
                privateKey = value
                message = "PEM imported locally. Select Save Connection to store it in Keychain."
            }
        }
        }
    }
    private func loadSensitiveFields() {
        token = ""
        clientID = ""
        clientSecret = ""
        keyID = ""
        privateKey = ""
    }
    private func load() {
        endpoint = ProviderSettings.endpoint(selected)
        loadSensitiveFields()
        message = ""
        testResult = nil
        testSucceeded = false
        hasCredential = ProviderAuthentication.hasCredential(selected)
        showLegacyAppleToken = false
    }
}
