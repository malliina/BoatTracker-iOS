import UIKit
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import MapboxMaps
import MSAL
import SwiftUI

@main
struct BoatApp: App {
    let log = LoggerFactory.shared.system(BoatApp.self)
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        AppCenter.start(withAppSecret: "adbb4491-3c8c-4893-bd16-cc8be65899a8", services: [
            Analytics.self,
            Crashes.self
        ])
    }
    
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var profileVm = ProfileVM()
    @StateObject private var tracksVm = TracksViewModel()
    @StateObject private var statsVm = StatsViewModel()
    @StateObject private var chartVm = ChartVM()
    @StateObject private var languageVm = LanguageVM()
    @StateObject private var tokensVm = BoatTokensVM()
//    @StateObject var activeTrack = ActiveTrack()
    
    var body: some Scene {
        WindowGroup {
            MainMapView<MapViewModel>()
                .environmentObject(viewModel)
                .environmentObject(profileVm)
                .environmentObject(tracksVm)
                .environmentObject(statsVm)
                .environmentObject(languageVm)
                .environmentObject(chartVm)
                .environmentObject(tokensVm)
//                .environmentObject(activeTrack)
                .task {
                    await viewModel.prepare()
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                MapEvents.shared.onBackground()
            }
            if phase == .active {
                let reconnect = MapEvents.shared.onForeground()
                if reconnect {
                    Task {
                        await Auth.shared.signInSilentlyNow()
                    }
                }
            }
        }
    }
}

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let log = LoggerFactory.shared.system(AppDelegate.self)
    
    var log: Logger { AppDelegate.log }
    let notifications = BoatNotifications.shared

    var window: UIWindow?

    
    /// https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content/handling_universal_links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL else {
                return false
        }
        log.info("Handled universal link from \(incomingURL).")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let googleAttempt = BoatGoogleAuth.shared.open(url: url, options: options)
        if googleAttempt {
            return true
        } else {
            return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await notifications.didRegister(deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task {
            await notifications.didFailToRegister(error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        log.info("Received remote notification...")
        notifications.handleNotification(application, window: window, data: userInfo)
    }
}

