//
//  BoatNotifications.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/10/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UserNotifications

protocol NotificationPermissionDelegate {
    func didRegister(_ token: PushToken)
    func didFailToRegister(_ error: Error)
}

open class BoatNotifications {
    let log = LoggerFactory.shared.system(BoatNotifications.self)
    static let shared = BoatNotifications()
    
    let settings = BoatPrefs.shared
    
    let noPushTokenValue = "none"
    let bag = DisposeBag()
    var permissionDelegate: NotificationPermissionDelegate? = nil
    
    func initNotifications(_ application: UIApplication) {
        // the playback notification is displayed as an alert to the user, so we must call this
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            if !granted {
                self.log.info("The user did not grant permission to send notifications")
                self.disableNotifications()
            } else {
            }
        }
        log.info("Registering with APNs...")
        // registers with APNs
        application.registerForRemoteNotifications()
    }
    
    func didRegister(_ deviceToken: Data) {
        let hexToken = deviceToken.hexString()
        let token = PushToken(token: hexToken)
        log.info("Got device token \(hexToken)")
        settings.pushToken = token
        settings.notificationsAllowed = true
        permissionDelegate?.didRegister(token)
    }
    
    func didFailToRegister(_ error: Error) {
        log.error("Remote notifications registration failure \(error.localizedDescription)")
        disableNotifications()
        permissionDelegate?.didFailToRegister(error)
    }
    
    func disableNotifications() {
        settings.pushToken = PushToken(token: BoatPrefs.shared.noPushTokenValue)
        settings.notificationsAllowed = false
    }
    
    func handleNotification(_ app: UIApplication, window: UIWindow?, data: [AnyHashable: Any]) {
//            let tag: String = try Json.readMapOrFail(data, "tag")
    }
    
    func onAlarmError(_ error: AppError) {
        log.error("Alarm error")
    }
}
