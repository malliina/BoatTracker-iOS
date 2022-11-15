import Foundation
import SwiftUI

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
                    .onChange(of: vm.notificationsEnabled) { enabled in
                        Task {
                            await vm.toggleNotifications(isEnabled: enabled)
                        }
                    }
            } header: {
                Spacer().frame(height: 8)
            } footer: {
                Text(lang.notificationsText)
                    .font(.system(size: 16))
                    .foregroundColor(BoatColor.shared.secondaryText)
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
                    .foregroundColor(BoatColor.shared.secondaryText)
            }
        }
        .listStyle(.plain)
        .sheet(item: $rename) { boat in
            NavigationView {
                VStack {
                    Text(boat.name.name)
                    TextField(lang.renameBoat, text: $newName)
                        .padding()
                    Button(lang.renameBoat) {
                        Task {
                            await vm.rename(boat: boat, newName: newName)
                        }
                    }
                    .padding()
                }
                .navigationTitle(lang.renameBoat)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(lang.cancel) {
                            rename = nil
                        }
                    }
                }
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
        if isEnabled {
            await registerNotifications()
        } else {
            await disableNotifications()
        }
    }
    
    func registerNotifications() async {
        notifications.permissionDelegate = self
        if let token = boatSettings.pushToken {
            log.info("Registering with previously saved push token...")
            await registerWithToken(token: token)
        } else {
            log.info("No saved push token. Asking for permission...")
            await notifications.initNotifications(.shared)
        }
    }
    
    func disableNotifications() async {
        if let token = boatSettings.pushToken {
            do {
                _ = try await http.disableNotifications(token: token)
                log.info("Disabled notifications with backend.")
            } catch {
                log.error("Failed to disable notifications with backend. \(error.describe)")
            }
        }
        notifications.disableNotifications()
    }
    
    func registerWithToken(token: PushToken) async {
        do {
            _ = try await http.enableNotifications(token: token)
            log.info("Enabled notifications with backend.")
        } catch {
            log.error(error.describe)
        }
    }
}

extension BoatTokensVM: NotificationPermissionDelegate {
    func didRegister(_ token: PushToken) async {
        if let token = boatSettings.pushToken {
            log.info("Permission granted.")
            await registerWithToken(token: token)
        } else {
            log.info("Access granted, but no token available.")
        }
    }
    
    func didFailToRegister(_ error: Error) async {
        await update(isEnabled: false)
        let error = AppError.simple("The user did not grant permission to send notifications")
        log.error(error.describe)
    }
    
    @MainActor private func update(isEnabled: Bool) {
        notificationsEnabled = isEnabled
    }
}
