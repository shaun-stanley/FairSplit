import Foundation

enum CloudSyncStatus: String {
    case unknown
    case available
    case missingEntitlement
    case accountUnavailable
    case error
}

enum CloudSyncStatusReporter {
    static func update(_ status: CloudSyncStatus, message: String? = nil) {
        let defaults = UserDefaults.standard
        defaults.set(status.rawValue, forKey: AppSettings.cloudSyncStatusKey)
        if let message {
            defaults.set(message, forKey: AppSettings.cloudSyncStatusMessageKey)
        } else {
            defaults.removeObject(forKey: AppSettings.cloudSyncStatusMessageKey)
        }
    }

    static func status() -> CloudSyncStatus {
        let raw = UserDefaults.standard.string(forKey: AppSettings.cloudSyncStatusKey)
        return CloudSyncStatus(rawValue: raw ?? CloudSyncStatus.unknown.rawValue) ?? .unknown
    }

    static func message() -> String? {
        UserDefaults.standard.string(forKey: AppSettings.cloudSyncStatusMessageKey)
    }
}

