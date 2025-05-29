import Foundation

protocol BoatTokensProtocol: ObservableObject {
  var notificationsEnabled: Bool { get set }
  var userProfile: UserProfile? { get }
  var appIcon: String { get }

  func load() async
  func rename(boat: Boat, newName: String) async
  func changeAppIcon(to: String) async
}

class BoatTokensVM: BoatTokensProtocol {
  static let shared = BoatTokensVM()
  let log = LoggerFactory.shared.vc(BoatTokensVM.self)
  private let notifications = BoatNotifications.shared
  @Published var notificationsEnabled: Bool
  @Published var userProfile: UserProfile?
  @Published var loadError: Error?
  @Published var appIcon: String

  let boatSettings = BoatPrefs.shared
  var app: UIApplication { UIApplication.shared }
  static let defaultAppIcon = "AppIcon"

  init() {
    notificationsEnabled = boatSettings.notificationsAllowed
    appIcon = UIApplication.shared.alternateIconName ?? BoatTokensVM.defaultAppIcon
    Task {
      // Waits for an ID token to be available before doing notification actions,
      // because toggling notifications on the backend requires an auth token.
      for await _ in Auth.shared.tokens.first().values {
        for await isEnabled in $notificationsEnabled.values {
          await toggleNotifications(isEnabled: isEnabled)
        }
      }
    }
  }

  func load() async {
    do {
      await update(profile: try await http.profile())
    } catch {
      log.info("Failed to load profile. \(error.describe)")
      await update(error: error)
    }
  }

  func rename(boat: Boat, newName: String) async {
    do {
      let boat = try await http.renameBoat(boat: boat.id, newName: BoatName(newName))
      log.info("Renamed to '\(boat.name)'.")
      await load()
    } catch {
      log.error("Unable to rename. \(error.describe)")
    }
  }

  @MainActor
  func changeAppIcon(to: String) async {
    let next = to == BoatTokensVM.defaultAppIcon ? nil : to
    log.info("Changing app icon to \(to)...")
    guard app.alternateIconName != next else {
      log.info("App icon is already \(to), ignoring change request.")
      return
    }
    log.info("Supports alternate icons: \(app.supportsAlternateIcons)")
    do {
      try await app.setAlternateIconName(next)
      log.info("Alternate icon set to \(to).")
      appIcon = to
    } catch {
      log.info("Failed to change alternate app icon. \(error)")
    }
  }

  @MainActor private func update(profile: UserProfile) {
    userProfile = profile
  }

  @MainActor private func update(error: Error) {
    loadError = error
  }

  func toggleNotifications(isEnabled: Bool) async {
    boatSettings.notificationsAllowed = isEnabled
    do {
      if isEnabled {
        try await registerNotifications()
      } else {

      }
    } catch {
      let word = isEnabled ? "enable" : "disable"
      log.error("Failed to \(word) notifications. \(error)")
    }
  }

  private func registerNotifications() async throws {
    notifications.permissionDelegate = self
    log.info("No saved push token. Asking for permission...")
    let granted = try await notifications.initNotifications(.shared)
    if !granted {
      await update(isEnabled: false)
      await openNotificationSettings()
    }
  }

  @MainActor
  func openNotificationSettings() {
    if let url = URL(string: appNotificationSettingsUrl) {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  var appNotificationSettingsUrl: String {
    if #available(iOS 16.0, *) {
      return UIApplication.openNotificationSettingsURLString
    } else {
      return UIApplication.openSettingsURLString
    }
  }
}

extension BoatTokensVM: NotificationPermissionDelegate {
  func didRegister(_ token: PushToken) async {
    if boatSettings.notificationsAllowed {
      do {
        let deviceId = BoatPrefs.shared.deviceId
        _ = try await http.enableNotifications(
          payload: PushPayload(
            token: token, device: .notification, deviceId: deviceId, liveActivityId: nil,
            trackName: nil))
        log.info("Enabled notifications for device \(deviceId) with backend.")
      } catch AppError.responseFailure(let details) {
        log.info("APNS registration failed. \(details.message ?? "Status \(details.code)")")
      } catch {
        log.info("Failed to register \(token). \(error)")
      }
    } else {
      log.info("Got APNS token, but notifications are not enabled on this device.")
    }
  }

  func didFailToRegister(_ error: Error) async {
    await update(isEnabled: false)
    let error = AppError.simple(
      "The user did not grant permission to send notifications. Enabled \(notificationsEnabled)")
    log.error(error.describe)
  }

  @MainActor private func update(isEnabled: Bool) {
    notificationsEnabled = isEnabled
  }
}
