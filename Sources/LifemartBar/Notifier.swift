import AppKit
import UserNotifications

/// Posts a banner when the order status changes, unless turned off in settings.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let enabledKey = "notificationsEnabled"

    /// True when macOS refuses notifications for the app (turned off in System Settings).
    private(set) var isBlocked = false

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            NSLog("LifemartBar: notifications granted=%d error=%@", granted, String(describing: error))
            DispatchQueue.main.async { self.isBlocked = !granted }
        }
    }

    func openSystemSettings() {
        let id = Bundle.main.bundleIdentifier ?? ""
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)")!)
    }

    func post(_ order: Order) {
        guard enabled else { return }
        send(title: "Заказ \(order.code): \(order.stage.title.lowercased())", body: order.statusText)
    }

    func sendTest() {
        send(title: "LifemartBar", body: "Так будут выглядеть уведомления о заказе")
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { NSLog("LifemartBar: notification failed: %@", String(describing: error)) }
        }
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
