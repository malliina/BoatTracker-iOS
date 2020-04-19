//
//  AppDelegate.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import UIKit
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Mapbox
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let logger = LoggerFactory.shared.system(AppDelegate.self)
    var log: Logger {
        AppDelegate.logger
    }
    let notifications = BoatNotifications.shared

    var window: UIWindow?
    
    var google: GoogleAuth?

//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        MSAppCenter.start("adbb4491-3c8c-4893-bd16-cc8be65899a8", withServices: [
            MSAnalytics.self,
            MSCrashes.self
        ])
        
        let _ = AppDelegate.initMapboxToken()
        
        google = GoogleAuth.shared

        //return true

        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        w.makeKeyAndVisible()
        w.rootViewController = MapVC()
        return true
    }
    
    /// https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content/handling_universal_links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL else {
                return false
        }
        log.info("Handled universal link from \(incomingURL).")
        return true
    }
    
    static func initMapboxToken(key: String = "MapboxAccessToken") -> Bool {
        do {
            let token = try Credentials.read(key: key)
            MGLAccountManager.accessToken = token
            return true
        } catch let err {
            AppDelegate.logger.error(err.describe)
            return false
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        google?.open(url: url, options: options) ?? false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        disconnectSocket()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        connectSocket()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notifications.didRegister(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        notifications.didFailToRegister(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        log.info("Received remote notification...")
        notifications.handleNotification(application, window: window, data: userInfo)
    }

    func connectSocket() {
        google?.signInSilently()
    }
    
    func disconnectSocket() {
        MapEvents.shared.close()
    }
}

