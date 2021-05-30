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
    static let log = LoggerFactory.shared.system(RxGoogleAuth.self)
    static let shared = RxGoogleAuth()
    let google = GIDSignIn.sharedInstance()!
    var log = RxGoogleAuth.log
    
    override init() {
        super.init()
        do {
            google.clientID = try Credentials.read(key: "GoogleClientId")
        } catch {
            log.error("Unable to read Google client ID. \(error)")
        }
    }
    
    func signIn(from: UIViewController) {
        google.presentingViewController = from
        google.signIn()
    }
    
    func obtainToken(from: UIViewController?) -> Single<UserToken?> {
        if let from = from {
            google.presentingViewController = from
        }
        let attempt = GoogleSignInAttempt()
        google.delegate = attempt
        google.restorePreviousSignIn()
        return attempt.result
    }
}

class GoogleSignInAttempt: NSObject, GIDSignInDelegate {
    static let log = LoggerFactory.shared.system(GoogleSignInAttempt.self)
    
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
            GoogleSignInAttempt.log.info("Got email '\(email)' with token '\(idToken)'.")
            subject.onNext(UserToken(email: email, token: AccessToken(idToken)))
            subject.onCompleted()
        }
    }
}
