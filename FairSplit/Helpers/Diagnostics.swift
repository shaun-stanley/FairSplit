import Foundation
import os

final class DiagnosticsLog {
    static let shared = DiagnosticsLog()
    private init() {}

    private let logger = Logger(subsystem: "com.sviftstudios.FairSplit", category: "app")
    private var buffer: [String] = []
    private let maxEntries = 500
    private let queue = DispatchQueue(label: "com.sviftstudios.FairSplit.diag", qos: .utility)

    func log(_ message: String) {
        guard UserDefaults.standard.bool(forKey: AppSettings.diagnosticsEnabledKey) else { return }
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)"
        logger.info("\(line, privacy: .public)")
        queue.async {
            if self.buffer.count >= self.maxEntries { self.buffer.removeFirst(self.buffer.count - self.maxEntries + 1) }
            self.buffer.append(line)
        }
    }

    func exportText() -> String {
        var snapshot: [String] = []
        queue.sync { snapshot = self.buffer }
        return snapshot.joined(separator: "\n")
    }
}

enum Diagnostics {
    static func event(_ message: String) {
        DiagnosticsLog.shared.log(message)
    }
}

