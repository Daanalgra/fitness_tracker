import Foundation
import UserNotifications

protocol RestNotificationScheduling {
    func requestAuthorizationIfNeeded()
    func scheduleRestNotification(endsAt: Date, title: String, body: String)
}

class SystemNotificationScheduler: RestNotificationScheduling {
    private let center: UNUserNotificationCenter
    init(center: UNUserNotificationCenter = .current()) { self.center = center }
    
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .authorized else { return }
            self.center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
    
    func scheduleRestNotification(endsAt: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, endsAt.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer-\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request) { _ in }
    }
}

