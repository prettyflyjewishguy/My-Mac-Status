import Foundation

// Alpha 2 is strictly read-only. No root execution, remediation, API credentials or network uploads.
enum MacHealthService {
    private struct Result { let output: String; let status: Int32; let timedOut: Bool }

    private static func run(_ executable: String, _ arguments: [String], timeout: TimeInterval = 12) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let group = DispatchGroup()
        group.enter()
        do { try process.run() } catch { return Result(output: error.localizedDescription, status: -1, timedOut: false) }
        DispatchQueue.global(qos: .utility).async { process.waitUntilExit(); group.leave() }
        let expired = group.wait(timeout: .now() + timeout) == .timedOut
        if expired { process.terminate(); _ = group.wait(timeout: .now() + 2) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(decoding: data.prefix(64_000), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return Result(output: text, status: process.isRunning ? -1 : process.terminationStatus, timedOut: expired)
    }

    private static func check(_ id: String, _ title: String, _ value: String, _ severity: CheckSeverity, _ detail: String, _ symbol: String) -> MacHealthCheck {
        MacHealthCheck(id: id, title: title, detail: detail, value: value, severity: severity, symbol: symbol)
    }

    static func scan() -> [MacHealthCheck] {
        [os(), fileVault(), sip(), mdm(), updates(), uptime()]
    }

    private static func os() -> MacHealthCheck {
        let r = run("/usr/bin/sw_vers", ["-productVersion"])
        let v = r.output
        guard r.status == 0, let major = Int(v.split(separator: ".").first ?? ""), major > 0 else {
            return check("os", "macOS Version", "Information unavailable", .unableToVerify, "Could not read the installed macOS version.", "desktopcomputer")
        }
        return check("os", "macOS Version", "macOS \(v)", major >= 14 ? .healthy : .needsAttention,
                     "Minimum supported macOS version: 14. ", "desktopcomputer")
    }

    private static func fileVault() -> MacHealthCheck {
        let r = run("/usr/bin/fdesetup", ["status"])
        let text = r.output.lowercased()
        if text.contains("filevault is on") { return check("filevault", "FileVault", "Enabled", .healthy, "Disk encryption is enabled.", "lock.shield") }
        if text.contains("filevault is off") { return check("filevault", "FileVault", "Disabled", .unhealthy, "FileVault disk encryption is disabled. Contact your support team.", "lock.shield") }
        return check("filevault", "FileVault", "Information unavailable", .unableToVerify, "FileVault status is temporarily unavailable. Try refreshing.", "lock.shield")
    }

    private static func sip() -> MacHealthCheck {
        let r = run("/usr/bin/csrutil", ["status"])
        let text = r.output.lowercased()
        if text.contains("status: enabled") { return check("sip", "System Integrity Protection", "Enabled", .healthy, "System Integrity Protection is enabled.", "checkmark.shield") }
        if text.contains("status: disabled") { return check("sip", "System Integrity Protection", "Disabled", .unhealthy, "System Integrity Protection is disabled. Contact your support team.", "checkmark.shield") }
        return check("sip", "System Integrity Protection", "Information unavailable", .unableToVerify, "Protection status is temporarily unavailable. Try refreshing.", "checkmark.shield")
    }

    private static func mdm() -> MacHealthCheck {
        let r = run("/usr/bin/profiles", ["status", "-type", "enrollment"])
        let text = r.output.lowercased()
        if text.contains("mdm enrollment: yes") { return check("mdm", "MDM Enrollment", "Enrolled", .healthy, "Your Mac is enrolled in your organization’s device management.", "building.2.crop.circle") }
        if text.contains("mdm enrollment: no") { return check("mdm", "MDM Enrollment", "Not enrolled", .unhealthy, "macOS reports that this Mac is not MDM-enrolled.", "building.2.crop.circle") }
        return check("mdm", "MDM Enrollment", "Information unavailable", .unableToVerify, "Enrollment information is temporarily unavailable.", "building.2.crop.circle")
    }

    // Alpha 5.3: read-only update discovery. Use softwareupdate's actual output,
    // including macOS 27's "* Label: ... / Title: ..., Version: ..." format.
    // Never interpret an incomplete scan as "no updates".
    private static func updates() -> MacHealthCheck {
        let r = run("/usr/sbin/softwareupdate", ["--list"], timeout: 75)
        if r.timedOut {
            return check("updates", "Software Updates", "Information unavailable", .unableToVerify,
                         "Apple's update scan exceeded 75 seconds. Open Software Update to check directly; nothing was installed.", "arrow.down.circle")
        }
        if r.status != 0 {
            return check("updates", "Software Updates", "Information unavailable", .unableToVerify,
                         "macOS could not complete the update scan. Open Software Update to check directly; nothing was installed.", "arrow.down.circle")
        }
        let text = r.output
        if text.localizedCaseInsensitiveContains("no new software available") ||
           text.localizedCaseInsensitiveContains("no updates are available") {
            return check("updates", "Software Updates", "No updates offered", .healthy,
                         "Your Mac is up to date with the updates currently offered.", "arrow.down.circle")
        }

        // A listed update begins at "* Label:" or a legacy "* ..." entry.
        // Only extract Version: from the same update entry; do not guess from unrelated lines.
        let versionPattern = try? NSRegularExpression(pattern: #"(?i)\bVersion:\s*([0-9]+(?:\.[0-9]+){1,3})\b"#)
        var entries: [String] = []
        var current = ""
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("* ") || line.hasPrefix("*\t") {
                if !current.isEmpty { entries.append(current) }
                current = line
            } else if !current.isEmpty && !line.isEmpty {
                current += " " + line
            }
        }
        if !current.isEmpty { entries.append(current) }
        guard !entries.isEmpty else {
            return check("updates", "Software Updates", "Information unavailable", .unableToVerify,
                         "Apple returned an unrecognized update listing. Open Software Update to confirm availability.", "arrow.down.circle")
        }
        // Only Apple's Label metadata may provide an offered build identifier.
        // Example: * Label: macOS 27.2-26B123
        // The version alone must never be used to infer a build.
        let buildPattern = try? NSRegularExpression(pattern: #"(?i)-([0-9]{2}[A-Z][0-9]{2,}[A-Z]?)\b"#)
        let installedResult = run("/usr/bin/sw_vers", ["-buildVersion"])
        let installedBuild = installedResult.status == 0 &&
            !installedResult.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? installedResult.output.trimmingCharacters(in: .whitespacesAndNewlines) : "Information unavailable"
        var versions: [String] = []
        var offeredBuilds: [(version: String, build: String)] = []
        for entry in entries {
            // The Title field (or older Label field) identifies macOS updates.
            let lower = entry.lowercased()
            guard lower.contains("macos") || lower.contains("mac os x") else { continue }
            if let regex = versionPattern {
                let range = NSRange(entry.startIndex..<entry.endIndex, in: entry)
                if let match = regex.firstMatch(in: entry, range: range),
                   let vr = Range(match.range(at: 1), in: entry) {
                    let version = String(entry[vr])
                    versions.append(version)
                    // Restrict build extraction to the Label portion, not Title or unrelated text.
                    let label = entry.components(separatedBy: ", Title:").first ?? entry
                    if let buildPattern = buildPattern {
                        let labelRange = NSRange(label.startIndex..<label.endIndex, in: label)
                        if let buildMatch = buildPattern.firstMatch(in: label, range: labelRange),
                           let br = Range(buildMatch.range(at: 1), in: label) {
                            offeredBuilds.append((version: version, build: String(label[br])))
                        }
                    }
                }
            }
        }
        let sorted = Array(Set(versions)).sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        if let newest = sorted.first {
            let all = sorted.map { "macOS " + $0 }.joined(separator: ", ")
            let availableBuild = offeredBuilds.first(where: { $0.version == newest })?.build ?? "Information unavailable"
            return check("updates", "Software Updates", "macOS \(newest) available", .needsAttention,
                         "Installed build: \(installedBuild)\nAvailable build: \(availableBuild)\nAvailable macOS version(s): \(all). No update was downloaded or installed. MDM deferrals may affect availability.", "arrow.down.circle")
        }
        return check("updates", "Software Updates", "Updates available", .needsAttention,
                     "Installed build: \(installedBuild)\nAvailable build: Information unavailable\nApple lists \(entries.count) available update(s), but a macOS version could not be confirmed. No installation was initiated.", "arrow.down.circle")
    }

    private static func uptime() -> MacHealthCheck {
        let r = run("/usr/sbin/sysctl", ["-n", "kern.boottime"])
        guard r.status == 0, let range = r.output.range(of: "sec = "),
              let seconds = Double(r.output[range.upperBound...].prefix(while: { $0.isNumber })) else {
            return check("uptime", "Last Restart", "Information unavailable", .unableToVerify, "Could not determine the last boot time.", "arrow.clockwise.circle")
        }
        let days = max(0, Int(Date().timeIntervalSince1970 - seconds) / 86400)
        return check("uptime", "Last Restart", days == 1 ? "1 day ago" : "\(days) days ago", days >= 7 ? .needsAttention : .healthy,
                     "Restarting your Mac weekly helps keep it running smoothly.", "arrow.clockwise.circle")
    }
}
