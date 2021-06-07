//
//  RxGoogleAuth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 23/12/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//
import Foundation
import GoogleSignIn
import RxCocoa
import RxSwift

class RxGoogleAuth: NSObject {
    let log = LoggerFactory.shared.system(RxGoogleAuth.self)
    static let shared = RxGoogleAuth()
    let google = GIDSignIn.sharedInstance()!
    private var latestAttempt: GoogleSignInAttempt? = nil
    
    override init() {
        super.init()
        do {
            google.clientID = try Credentials.read(key: "GoogleClientId")
        } catch {
            log.error("Unable to read Google client ID. \(error)")
        }
    }
    
    func signInSilently() {
        google.restorePreviousSignIn()
    }
    
    func obtainToken(from: UIViewController?, restore: Bool) -> Single<UserToken?> {
        let attempt = GoogleSignInAttempt()
        latestAttempt = attempt
        google.delegate = attempt
        if let from = from {
            google.presentingViewController = from
        }
        if restore {
            google.restorePreviousSignIn()
        } else {
            google.signIn()
        }
        return attempt.result
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return google.handle(url)
    }
}

class GoogleSignInAttempt: NSObject, GIDSignInDelegate {
    let log = LoggerFactory.shared.system(GoogleSignInAttempt.self)
    
    private let subject = ReplaySubject<UserToken?>.create(bufferSize: 1)
    var result: Single<UserToken?> { subject.asSingle() }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            subject.onError(error)
        } else {
            guard let idToken = user.authentication.idToken else {
                subject.onError(AppError.simple("No ID token in Google sign in response."))
                return
            }
            BoatPrefs.shared.authProvider = .google
            let email = user.profile.email ?? "unknown"
            log.info("Got email '\(email)' with token '\(idToken)'.")
            subject.onNext(UserToken(email: email, token: AccessToken(idToken)))
            subject.onCompleted()
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        log.info("Google disconnected.")
    }
}
