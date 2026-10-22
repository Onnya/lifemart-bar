import Foundation
import UserNotifications

/// Posts a banner when the order status changes, unless turned off in settings.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let enabledKey = "notificationsEnabled"

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(_ order: Order) {
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Заказ \(order.code): \(order.stage.title.lowercased())"
        content.body = order.statusText
        content.sound = .default
        let request = UNNotificationRequest(identifier: "order-\(order.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // Show banners even though the menu-bar app counts as frontmost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
