import Foundation
import IOKit.ps

// Feature 2.3: read-only local observations. Never install updates or modify profiles.
struct UpdateReadinessResult {
    let checkedAt: Date
    let installed: String
    let availability: String
    let readiness: String
    let recommendation: String
    let findings: [String]
}

enum UpdateIntelligenceService {
    private static func command(_ executable: String, _ arguments: [String], timeout: TimeInterval = 90) -> (Int32, String)? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do { try process.run() } catch { return nil }
        // Drain concurrently so a full pipe cannot block process termination.
        let lock = NSLock()
        var bytes = Data()
        let drain = DispatchGroup()
        drain.enter()
        DispatchQueue.global(qos: .utility).async {
            let handle = output.fileHandleForReading
            while true {
                let part = handle.availableData
                if part.isEmpty { break }
                lock.lock()
                if bytes.count < 131_072 { bytes.append(part.prefix(131_072 - bytes.count)) }
                lock.unlock()
            }
            drain.leave()
        }
        let finished = DispatchGroup()
        finished.enter()
        DispatchQueue.global(qos: .utility).async { process.waitUntilExit(); finished.leave() }
        if finished.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            if finished.wait(timeout: .now() + 3) == .timedOut { return nil }
            _ = drain.wait(timeout: .now() + 2)
            return nil
        }
        _ = drain.wait(timeout: .now() + 2)
        lock.lock()
        let text = String(decoding: bytes, as: UTF8.self)
        lock.unlock()
        return (process.terminationStatus, text)
    }

    static func check() -> UpdateReadinessResult {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let build = command("/usr/bin/sw_vers", ["-buildVersion"], timeout: 5)?.1.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Not checked build"
        let installed = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion) (\(build))"
        var findings: [String] = []
        var concerns = false
        if let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]), let capacity = values.volumeAvailableCapacityForImportantUsage ?? values.volumeAvailableCapacity.map(Int64.init) {
            // Use capacity available for important usage when assessing update
            // readiness; do not confuse this with strictly unallocated blocks.
            let gib = Double(capacity) / 1_073_741_824
            findings.append(String(format: "You have %.1f GB of storage available.", gib))
            if gib < 25 {
                concerns = true
                findings.append("Your Mac may need more free space before updating. The amount depends on the update.")
            }
        } else { findings.append("We couldn’t check your available storage.") }

        if let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                   let state = description[kIOPSPowerSourceStateKey as String] as? String {
                    let onAC = state == (kIOPSACPowerValue as String)
                    findings.append(onAC ? "Your Mac is connected to power." : "Your Mac is on battery power. Plug it in before installing a large update.")
                    break
                }
            }
        }

        if let managed = command("/usr/bin/profiles", ["status", "-type", "enrollment"], timeout: 12),
           managed.1.localizedCaseInsensitiveContains("MDM enrollment: Yes") {
            findings.append("Your Mac is managed by an organization, which may control when updates appear. We haven’t confirmed any specific restrictions.")
        }

        guard let listing = command("/usr/sbin/softwareupdate", ["--list"], timeout: 90), listing.0 == 0 else {
            findings.append("We couldn’t finish checking for updates. Open Software Update in System Settings to try again.")
            return UpdateReadinessResult(checkedAt: Date(), installed: installed, availability: "Couldn’t check", readiness: "Not checked", recommendation: "Open Software Update to check again", findings: findings)
        }
        let lower = listing.1.lowercased()
        if lower.contains("no new software available") || lower.contains("no updates are available") {
            findings.append("Your Mac isn’t showing any available updates right now. This doesn’t necessarily mean it has the latest public macOS release.")
            return UpdateReadinessResult(checkedAt: Date(), installed: installed, availability: "No updates available right now", readiness: concerns ? "A little preparation needed" : "No issues found in this check", recommendation: concerns ? "Free up some storage before updating" : "You’re all set for now", findings: findings)
        }
        let lines = listing.1.components(separatedBy: .newlines)
        let labels = lines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.hasPrefix("* ") || $0.hasPrefix("*\t") }
        guard !labels.isEmpty else {
            findings.append("We couldn’t understand the update results. Open Software Update to check again.")
            return UpdateReadinessResult(checkedAt: Date(), installed: installed, availability: "Couldn’t check", readiness: "Not checked", recommendation: "Open Software Update to check again", findings: findings)
        }
        let sample = labels.prefix(3).map { String($0.dropFirst(2)) }
        findings.append("Available from macOS: " + sample.joined(separator: "; ") + (labels.count > 3 ? " (and more)" : ""))
        findings.append("We haven’t checked whether your apps are compatible or whether this update has known issues.")
        let majorUpgrade = sample.contains { $0.localizedCaseInsensitiveContains("upgrade") || $0.localizedCaseInsensitiveContains("macOS \(version.majorVersion + 1)") }
        let advice = concerns ? "Free up some storage before updating" : majorUpgrade ? "Before upgrading, check your apps and any guidance from your organization" : "Review the update and any guidance from your organization before installing"
        return UpdateReadinessResult(checkedAt: Date(), installed: installed, availability: "Updates available (\(labels.count))", readiness: concerns ? "A little preparation needed" : "No issues found in this check", recommendation: advice, findings: findings)
    }
}
