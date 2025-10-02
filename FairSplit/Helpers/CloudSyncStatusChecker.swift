import CloudKit
import Foundation

enum CloudSyncStatusChecker {
    static func refresh() {
        guard CloudSyncEntitlement.hasCloudKitAccess() else {
            CloudSyncStatusReporter.update(.missingEntitlement)
            return
        }

        let container = CKContainer(identifier: AppSettings.cloudKitContainerIdentifier)
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error as? CKError {
                    handleCloudKitError(error)
                } else if let error {
                    CloudSyncStatusReporter.update(.error, message: error.localizedDescription)
                } else {
                    handleAccountStatus(status)
                }
            }
        }
    }

    private static func handleAccountStatus(_ status: CKAccountStatus) {
        switch status {
        case .available:
            CloudSyncStatusReporter.update(.available)
        case .noAccount, .restricted:
            CloudSyncStatusReporter.update(.accountUnavailable)
        case .couldNotDetermine:
            CloudSyncStatusReporter.update(.error, message: "Could not determine iCloud account status.")
        case .temporarilyUnavailable:
            CloudSyncStatusReporter.update(.error, message: "iCloud is temporarily unavailable. Try again later.")
        @unknown default:
            CloudSyncStatusReporter.update(.error, message: "Unknown iCloud account status.")
        }
    }

    private static func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .notAuthenticated:
            CloudSyncStatusReporter.update(.accountUnavailable)
        case .permissionFailure:
            CloudSyncStatusReporter.update(.missingEntitlement)
        default:
            CloudSyncStatusReporter.update(.error, message: error.localizedDescription)
        }
    }
}
