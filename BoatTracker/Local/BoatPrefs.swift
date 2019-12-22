//
//  BoatPrefs.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 24/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class BoatPrefs {
    static let shared = BoatPrefs()
    let prefs = UserDefaults.standard

    let welcomeKey = "welcome"
    let pushTokenKey = "pushToken"
    let notificationsAllowedKey = "notificationsAllowed"
    let noPushTokenValue = "none"

    var isWelcomeRead: Bool {
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
//            if errors == nil {
//                notificationPermissionSubject.onNext(allowed)
//            }
        }
    }
}
