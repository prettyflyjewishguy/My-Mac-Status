import Foundation
import IOKit.ps

enum BatteryReader {
    static func run(_ executable: String, _ args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }

    static func number(_ value: Any?) -> Int? {
        if let n = value as? NSNumber { return n.intValue }
        if let s = value as? String { return Int(s) }
        return nil
    }
    static func boolean(_ value: Any?) -> Bool? {
        if let n = value as? NSNumber { return n.boolValue }
        if let s = value as? String { return ["yes", "true", "1"].contains(s.lowercased()) }
        return nil
    }
    static func field(_ name: String, in text: String) -> String? {
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix(name.lowercased() + ":") {
                return String(trimmed.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    static func read() -> BatterySnapshot {
        var result = BatterySnapshot()
        let sourceInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(sourceInfo).takeRetainedValue() as [CFTypeRef]
        if !sources.isEmpty {
            for source in sources {
                guard let info = IOPSGetPowerSourceDescription(sourceInfo, source).takeUnretainedValue() as? [String: Any],
                      (info[kIOPSTypeKey as String] as? String) == (kIOPSInternalBatteryType as String) else { continue }
                result.charge = number(info[kIOPSCurrentCapacityKey as String])
                result.connected = (info[kIOPSPowerSourceStateKey as String] as? String) == (kIOPSACPowerValue as String)
                result.charging = boolean(info[kIOPSIsChargingKey as String])
                break
            }
        }

        if let xml = run("/usr/sbin/ioreg", ["-a", "-r", "-c", "AppleSmartBattery"]),
           let data = xml.data(using: .utf8),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
           let items = plist as? [[String: Any]], let battery = items.first {
            result.cycles = number(battery["CycleCount"])
            result.connected = boolean(battery["ExternalConnected"]) ?? result.connected
            result.charging = boolean(battery["IsCharging"]) ?? result.charging
            if let adapter = battery["AdapterDetails"] as? [String: Any] {
                result.watts = number(adapter["Watts"])
            }
            let design = number(battery["DesignCapacity"])
            let maximum = number(battery["AppleRawMaxCapacity"]) ?? number(battery["MaxCapacity"])
            if let design, let maximum, design > 0 {
                result.maxCapacity = min(100, max(0, Int((Double(maximum) / Double(design) * 100).rounded())))
            }
        }
        // Apple's user-facing condition/capacity can differ from raw controller values.
        // Prefer the values explicitly reported by System Information when available.
        if let power = run("/usr/sbin/system_profiler", ["SPPowerDataType"]) {
            if let condition = field("Condition", in: power) { result.condition = condition }
            if let capacity = field("Maximum Capacity", in: power),
               let digits = capacity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().isEmpty ? nil : Int(capacity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                result.maxCapacity = digits
            }
            if result.cycles == nil { result.cycles = field("Cycle Count", in: power).flatMap(Int.init) }
            if result.watts == nil { result.watts = field("Wattage (W)", in: power).flatMap(Int.init) }
        }
        if result.charge == nil && result.cycles == nil {
            result.error = "No internal battery was detected. This app is designed for Mac notebooks."
        }
        return result
    }
}

