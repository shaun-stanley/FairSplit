import Foundation

enum CloudSyncEntitlement {
    static func hasCloudKitAccess() -> Bool {
        guard let identifiers = Bundle.main.object(forInfoDictionaryKey: "iCloudContainers") as? [String] else {
            return false
        }
        return identifiers.contains(AppSettings.cloudKitContainerIdentifier)
    }
}

