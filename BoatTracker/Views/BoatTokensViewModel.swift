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
            for await isEnabled in $notificationsEnabled.values {
                await toggleNotifications(isEnabled: isEnabled)
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
        do {
            if isEnabled {
                try await registerNotifications()
            } else {
                try await disableNotifications()
            }
        } catch {
            let word = isEnabled ? "enable" : "disable"
            log.error("Failed to \(word) notifications. \(error)")
        }
    }
    
    func registerNotifications() async throws {
        notifications.permissionDelegate = self
        if let token = boatSettings.pushToken {
            log.info("Registering with previously saved push token...")
            try await registerWithToken(token: token)
        } else {
            log.info("No saved push token. Asking for permission...")
            let granted = try await notifications.initNotifications(.shared)
            if !granted {
                await update(isEnabled: false)
                await openNotificationSettings()
            }
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
    
    func disableNotifications() async throws {
        if let token = boatSettings.pushToken {
            _ = try await http.disableNotifications(token: token)
            log.info("Disabled notifications with backend.")
        }
        notifications.disableNotifications()
    }
    
    func registerWithToken(token: PushToken) async throws {
        _ = try await http.enableNotifications(token: token)
        log.info("Enabled notifications with backend.")
    }
}

extension BoatTokensVM: NotificationPermissionDelegate {
    func didRegister(_ token: PushToken) async {
        log.info("Permission granted.")
        if let token = boatSettings.pushToken {
            do {
                try await registerWithToken(token: token)
            } catch {
                log.info("Failed to register \(token). \(error)")
            }
        } else {
            log.info("Permission granted, but no token available.")
        }
    }
    
    func didFailToRegister(_ error: Error) async {
        await update(isEnabled: false)
        let error = AppError.simple("The user did not grant permission to send notifications. Enabled \(notificationsEnabled)")
        log.error(error.describe)
    }
    
    @MainActor private func update(isEnabled: Bool) {
        notificationsEnabled = isEnabled
    }
}
