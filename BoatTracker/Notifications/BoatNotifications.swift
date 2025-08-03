import ActivityKit
import Foundation
import UserNotifications

protocol NotificationPermissionDelegate {
  func didRegister(_ token: PushToken) async
  func didFailToRegister(_ error: Error) async
}

class BoatNotifications {
  let log = LoggerFactory.shared.system(BoatNotifications.self)
  static let shared = BoatNotifications()

  let settings = BoatPrefs.shared

  let noPushTokenValue = "none"
  var permissionDelegate: NotificationPermissionDelegate? = nil

  func initNotifications(_ application: UIApplication) async throws -> Bool {
    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
      .alert, .sound, .badge,
    ])
    if granted {
      log.info("Registering with APNs...")
      // registers with APNs
      await application.registerForRemoteNotifications()
      return true
    } else {
      log.info("The user did not grant permission to send notifications")
      settings.notificationsAllowed = false
      return false
    }
  }

  func didRegister(_ deviceToken: Data) async {
    let hexToken = deviceToken.hexString()
    let token = PushToken(hexToken)
    log.info("Got device token \(hexToken)")
    await permissionDelegate?.didRegister(token)
  }

  func didFailToRegister(_ error: Error) async {
    log.error("Remote notifications registration failure \(error.describe)")
    await permissionDelegate?.didFailToRegister(error)
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
