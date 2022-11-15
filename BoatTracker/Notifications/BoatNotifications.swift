import Foundation
import UserNotifications

protocol NotificationPermissionDelegate {
    func didRegister(_ token: PushToken) async
    func didFailToRegister(_ error: Error) async
}

open class BoatNotifications {
    let log = LoggerFactory.shared.system(BoatNotifications.self)
    static let shared = BoatNotifications()
    
    let settings = BoatPrefs.shared
    
    let noPushTokenValue = "none"
    var permissionDelegate: NotificationPermissionDelegate? = nil
    
    func initNotifications(_ application: UIApplication) async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                log.info("Registering with APNs...")
                // registers with APNs
                await application.registerForRemoteNotifications()
            } else {
                log.info("The user did not grant permission to send notifications")
                disableNotifications()
            }
        } catch {
            log.error("Failed to init notifications. \(error.describe)")
        }
    }
    
    func didRegister(_ deviceToken: Data) async {
        let hexToken = deviceToken.hexString()
        let token = PushToken(hexToken)
        log.info("Got device token \(hexToken)")
        settings.pushToken = token
        settings.notificationsAllowed = true
        await permissionDelegate?.didRegister(token)
    }
    
    func didFailToRegister(_ error: Error) async {
        log.error("Remote notifications registration failure \(error.localizedDescription)")
        disableNotifications()
        await permissionDelegate?.didFailToRegister(error)
    }
    
    func disableNotifications() {
        settings.pushToken = PushToken(BoatPrefs.shared.noPushTokenValue)
        settings.notificationsAllowed = false
    }
    
    func handleNotification(_ app: UIApplication, window: UIWindow?, data: [AnyHashable: Any]) {
        do {
            guard let meta = data["meta"] else { return }
            let metaData = try JSONSerialization.data(withJSONObject: meta)
            let decoder = JSONDecoder()
            let notification = try decoder.decode(BoatNotification.self, from: metaData)
            log.info("Got \(notification.state) notification for boat \(notification.boatName)")
        } catch let err {
            log.error("Failed to parse notification. \(err.describe)")
        }
    }
    
    func onAlarmError(_ error: AppError) {
        log.error("Alarm error")
    }
}
