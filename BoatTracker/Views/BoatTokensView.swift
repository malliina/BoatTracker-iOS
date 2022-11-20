import Foundation
import SwiftUI
import Combine

struct TokensLang {
    let notificationsText, notifications, boat, token, tokenText, renameBoat, newName, failText, cancel: String
    
    static func build(lang: Lang) -> TokensLang {
        let settings = lang.settings
        return TokensLang(notificationsText: settings.notificationsText, notifications: settings.notifications, boat: settings.boat, token: settings.token, tokenText: settings.tokenText, renameBoat: settings.renameBoat, newName: settings.newName, failText: lang.messages.failedToLoadProfile, cancel: settings.cancel)
    }
}

struct BoatTokensView: View {
    let log = LoggerFactory.shared.vc(BoatTokensView.self)
    let spacing: CGFloat = 12
    let lang: TokensLang
    @ObservedObject var vm: BoatTokensVM
    
    @State var rename: Boat? = nil
    @State var newName: String = ""
    var renamePresented: Binding<Bool> {
        Binding(get: { rename != nil }, set: { _ in () })
    }
    
    var body: some View {
        List {
            Section {
                Toggle(lang.notifications, isOn: $vm.notificationsEnabled)
            } header: {
                Spacer().frame(height: 8)
            } footer: {
                Text(lang.notificationsText)
                    .font(.system(size: 16))
                    .foregroundColor(color.secondaryText)
            }
            Section {
                if let boats = vm.userProfile?.boats {
                    ForEach(boats) { boat in
                        Button {
                            rename = boat
                        } label: {
                            HStack {
                                Spacer()
                                StatView(label: lang.boat, value: boat.name, style: .large)
                                Spacer()
                                StatView(label: lang.token, value: boat.token, style: .large)
                                Spacer()
                            }
                        }
                    }
                }
            } footer: {
                Text(lang.tokenText)
                    .font(.system(size: 16))
                    .foregroundColor(color.secondaryText)
            }
        }
        .listStyle(.plain)
        .sheet(item: $rename) { boat in
            EditDialog(navTitle: lang.renameBoat, title: lang.renameBoat, message: boat.name.name, initialValue: "", ctaTitle: lang.renameBoat, cancel: lang.cancel) { newName in
                await vm.rename(boat: boat, newName: newName)
            }
        }
        .task {
            await vm.load()
        }
    }
}

struct BoatTokensPreview: PreviewProvider {
    static var previews: some View {
        Text("Todo")
    }
}

class BoatTokensVM: ObservableObject {
    let log = LoggerFactory.shared.vc(BoatTokensVM.self)
    private let http = Backend.shared.http
    private let notifications = BoatNotifications.shared
    
    @Published var notificationsEnabled: Bool
    @Published var userProfile: UserProfile?
    @Published var loadError: Error?
    
    let boatSettings = BoatPrefs.shared
    
    init() {
        notificationsEnabled = boatSettings.notificationsAllowed
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
