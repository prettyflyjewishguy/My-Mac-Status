import SwiftUI

@MainActor final class CompanionModel: ObservableObject {
    @Published var selection: CompanionPage? = .dashboard
    @Published var battery = BatterySnapshot()
    @Published var device = DeviceInfo()
    @Published var loading = false
    @Published private(set) var batteryRefreshing = false
    @Published private(set) var refreshMessage: String?
    private let healthFreshnessInterval: TimeInterval = 5 * 60
    private let batteryFreshnessInterval: TimeInterval = 60
    private var batteryRefreshToken: UUID?
    @Published var macHealth = MacHealthSnapshot()
    @Published var storageSelectedTab = 0
    @Published var storage = StorageSnapshot()
    @Published var lastRefresh: Date?

    func scanStorage() {
        guard !storage.isScanning else { return }
        storage.isScanning = true
        storage.error = nil
        Task.detached(priority: .userInitiated) {
            let result = StorageService.scanHome()
            await MainActor.run {
                self.storage.entries = result.entries
                self.storage.scannedItems = result.scannedItems
                self.storage.skippedItems = result.skippedItems
                self.storage.error = result.error
                self.storage.scannedAt = Date()
                self.storage.isScanning = false
            }
        }
    }

    // One coordinated main refresh. Navigation never starts a second scan while this runs.
    func refreshHealthIfStale() {
        guard !loading else { return }
        guard let checkedAt = macHealth.checkedAt else { refresh(); return }
        if Date().timeIntervalSince(checkedAt) >= healthFreshnessInterval { refresh() }
    }

    // Battery-only refresh is intentionally separate from the slower Mac Health scan.
    // A main refresh takes precedence; its result is never overwritten by an older battery read.
    func refreshBatteryIfStale() {
        guard !loading && !batteryRefreshing else { return }
        if battery.error == nil && Date().timeIntervalSince(battery.captured) < batteryFreshnessInterval { return }
        batteryRefreshing = true
        let token = UUID()
        batteryRefreshToken = token
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = BatteryReader.read()
            await MainActor.run {
                guard let self, self.batteryRefreshToken == token else { return }
                if result.error == nil {
                    self.battery = result
                } else {
                    var retained = self.battery
                    retained.error = "Battery information isn't available right now. Try refreshing again."
                    self.battery = retained
                }
                self.batteryRefreshing = false
                self.batteryRefreshToken = nil
            }
        }
    }

    func refresh() {
        guard !loading else { return }
        // Invalidate any pending battery-only result so it cannot overwrite the full refresh.
        batteryRefreshToken = nil
        batteryRefreshing = false
        loading = true
        refreshMessage = nil
        macHealth.isScanning = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let device = DeviceInfoService.read()
            let battery = BatteryReader.read()
            let checks = MacHealthService.scan()
            await MainActor.run {
                guard let self else { return }
                self.device = device
                if battery.error == nil {
                    self.battery = battery
                } else {
                    var retained = self.battery
                    retained.error = "Battery information isn't available right now. Try refreshing again."
                    self.battery = retained
                }
                self.macHealth.checks = checks
                self.macHealth.checkedAt = Date()
                self.macHealth.isScanning = false
                self.lastRefresh = Date()
                self.loading = false
                if checks.isEmpty {
                    self.refreshMessage = "Some Mac health information couldn't be loaded. Try refreshing again."
                }
            }
        }
    }
}
