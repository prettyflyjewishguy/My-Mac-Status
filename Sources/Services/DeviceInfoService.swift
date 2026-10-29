import Foundation
import AppKit
import IOKit
import Darwin

enum DeviceInfoService {
    private static func sysctlString(_ name: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &bytes, &size, nil, 0) == 0 else { return nil }
        return String(decoding: bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
    static func read() -> DeviceInfo {
        var info = DeviceInfo()
        info.computerName = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        info.model = sysctlString("hw.model") ?? "Unavailable"
        info.processor = "Apple Silicon"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        info.macOS = "macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if service != 0 {
            if let serial = IORegistryEntryCreateCFProperty(service, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String,
               !serial.isEmpty { info.serial = serial }
            IOObjectRelease(service)
        }
        let root = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? root.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]) {
            info.freeBytes = values.volumeAvailableCapacity.map(Int64.init)
            info.totalBytes = values.volumeTotalCapacity.map(Int64.init)
        }
        info.captured = Date()
        return info
    }
}
