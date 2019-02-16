//
//  GoogleAuth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 13/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import GoogleSignIn

class GoogleAuth: NSObject, GIDSignInDelegate {
    static let shared = GoogleAuth()
    static let logger = LoggerFactory.shared.system(GoogleAuth.self)
    
    let log = GoogleAuth.logger
    
    var delegate: TokenDelegate? = nil
    var uiDelegate: TokenDelegate? = nil
    
    let google = GIDSignIn.sharedInstance()!
    
    override init() {
        super.init()
        do {
            google.clientID = try Credentials.read(key: "GoogleClientId")
        } catch {
            GoogleAuth.logger.error("Unable to read Google client ID. \(error)")
        }
        google.delegate = self
    }
    
    /// If the user is authenticated, this will eventually call the delegate with the Google id token.
    ///
    /// If the user is unauthenticated, this will call the delegate with a nil token.
    func signInSilently() {
        google.signInSilently()
    }
    
    func signOut() {
        google.signOut()
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return google.handle(url as URL?,
                             sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                             annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            log.error("Sign in error: '\(error.localizedDescription)'.")
            onToken(token: nil)
        } else {
            // Perform any operations on signed in user here.
//            let userId = user.userID                  // For client-side use only!
//            let fullName = user.profile.name
//            let givenName = user.profile.givenName
//            let familyName = user.profile.familyName
//            let email = user.profile.email
            guard let idToken = user.authentication.idToken else {
                log.error("No ID token in Google response.")
                onToken(token: nil)
                return
            }
            let email = user.profile.email ?? "unknown"
            log.info("Got email '\(email)' with token '\(idToken)'.")
            onToken(token: UserToken(email: email, token: AccessToken(idToken)))
        }
    }
    
    func onToken(token: UserToken?) {
        uiDelegate?.onToken(token: token)
        delegate?.onToken(token: token)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        log.info("User disconnected.")
    }

}
