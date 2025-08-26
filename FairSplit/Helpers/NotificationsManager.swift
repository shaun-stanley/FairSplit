import Foundation
import UserNotifications

enum NotificationsManager {
    static let dailyIdentifier = "daily.reminder"

    static func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    static func scheduleDailyReminder(hour: Int, minute: Int) {
        cancelDailyReminder()
        let content = UNMutableNotificationContent()
        content.title = "FairSplit Reminder"
        content.body = "Take a moment to log recurring expenses or settle up."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: dailyIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
    }

    static func refreshFromSettings() {
        let enabled = UserDefaults.standard.bool(forKey: AppSettings.notificationsEnabledKey)
        let hour = UserDefaults.standard.integer(forKey: AppSettings.notificationsHourKey)
        let minute = UserDefaults.standard.integer(forKey: AppSettings.notificationsMinuteKey)
        if enabled {
            requestAuthorizationIfNeeded { granted in
                if granted {
                    scheduleDailyReminder(hour: hour, minute: minute)
                }
            }
        } else {
            cancelDailyReminder()
        }
    }
}

