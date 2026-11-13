import Foundation

struct CommunityDiagnosticRecord: Identifiable, Codable {
    var id = UUID()
    var checkedAt = Date()
    let name: String
    let result: String
    let succeeded: Bool
}

enum CommunityDiagnosticService {
    // Local read-only network checks. No repairs, uploads, credentials, or privileged commands.
    static func run() -> [CommunityDiagnosticRecord] {
        [probe("DNS resolution", executable: "/usr/bin/dig", args: ["+time=2", "+tries=1", "+short", "apple.com"]),
         probe("Apple HTTPS connectivity", executable: "/usr/bin/nc", args: ["-G", "4", "-z", "www.apple.com", "443"]),
         probe("Apple push connectivity", executable: "/usr/bin/nc", args: ["-G", "4", "-z", "courier.push.apple.com", "5223"])]
    }
    private static func probe(_ name: String, executable: String, args: [String]) -> CommunityDiagnosticRecord {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            let deadline = Date().addingTimeInterval(8)
            while task.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.1) }
            if task.isRunning { task.terminate(); return .init(name: name, result: "Timed out", succeeded: false) }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data.prefix(2000), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let success = task.terminationStatus == 0 && (name != "DNS resolution" || !output.isEmpty)
            return .init(name: name, result: success ? "Reachable" : "Unable to verify", succeeded: success)
        } catch { return .init(name: name, result: "Unavailable: \(error.localizedDescription)", succeeded: false) }
    }
}
