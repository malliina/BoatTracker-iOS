import Foundation

class BoatPrefs {
    static let shared = BoatPrefs()
    let prefs = UserDefaults.standard

    let authProviderKey = "authProvider"
    let welcomeKey = "welcome"
    let pushTokenKey = "pushToken"
    let notificationsAllowedKey = "notificationsAllowed"
    let noPushTokenValue = "none"
    let aisKey = "aisEnabled"

    var showWelcome: Bool {
        get {
            prefs.bool(forKey: welcomeKey)
        }
        set(newValue) {
            prefs.set(newValue, forKey: welcomeKey)
        }
    }

    var pushToken: PushToken? {
        get {
            let tokenString = prefs.string(forKey: pushTokenKey)
            if let tokenString = tokenString {
                if tokenString != noPushTokenValue {
                    return PushToken(tokenString)
                }
            }
            return nil
        }
        set(newToken) {
            let token = newToken?.token ?? noPushTokenValue
            prefs.set(token, forKey: pushTokenKey)
        }
    }

    var notificationsAllowed: Bool {
        get {
            prefs.bool(forKey: notificationsAllowedKey) == true
        }
        set(allowed) {
            prefs.set(allowed, forKey: notificationsAllowedKey)
        }
    }

    // Defaults to true by negation. Reading a boolean when the key doesn't exist returns false.
    var isAisEnabled: Bool {
        get {
            !prefs.bool(forKey: aisKey)
        }
        set(newValue) {
            prefs.set(!newValue, forKey: aisKey)
        }
    }
    
    var authProvider: AuthProvider {
        get {
            guard let str = prefs.string(forKey: authProviderKey) else { return .none }
            return AuthProvider(rawValue: str) ?? .none
        }
        set(newValue) {
            prefs.set(newValue.rawValue, forKey: authProviderKey)
        }
    }
}
