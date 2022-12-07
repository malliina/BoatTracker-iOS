import Foundation
import UIKit
import MSAL
import Combine
import SwiftUI

protocol WelcomeDelegate {
    func showWelcome(token: UserToken?) async
}

class AuthVM: ObservableObject {
    let log = LoggerFactory.shared.vc(AuthVM.self)
    
    var prefs: BoatPrefs { BoatPrefs.shared }
    
    func clicked(provider: AuthProvider) {
        prefs.authProvider = provider
        prefs.showWelcome = true
    }
    
    func showWelcome(token: UserToken?, lang: Lang) async -> WelcomeInfo? {
        BoatPrefs.shared.showWelcome = false
        do {
            let profile = try await http.profile()
                if let boatToken = profile.boats.headOption()?.token {
                return WelcomeInfo(boatToken: boatToken, lang: lang.settings)
            } else {
                log.warn("Signed in but user has no boats.")
            }
        } catch {
            log.error("Failed to load profile. \(error)")
        }
        return nil
    }
}
