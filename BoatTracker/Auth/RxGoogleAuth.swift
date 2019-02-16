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

class RxGoogleAuth: NSObject, GIDSignInDelegate {
    static let log = LoggerFactory.shared.system(GoogleAuth.self)
    let google = GIDSignIn.sharedInstance()!
    var log = RxGoogleAuth.log
    
    private let subject = ReplaySubject<UserToken>.create(bufferSize: 1)
    
    override init() {
        super.init()
        do {
            google.clientID = try Credentials.read(key: "GoogleClientId")
        } catch {
            GoogleAuth.logger.error("Unable to read Google client ID. \(error)")
        }
        google.delegate = self
    }
    
    func signIn() -> Single<UserToken> {
        google.signInSilently()
        return subject.asSingle()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            subject.onError(error)
        } else {
            guard let idToken = user.authentication.idToken else {
                subject.onError(AppError.simple("No ID token in Google sign in response."))
                return
            }
            let email = user.profile.email ?? "unknown"
            log.info("Got email '\(email)' with token '\(idToken)'.")
            subject.onNext(UserToken(email: email, token: AccessToken(idToken)))
            subject.onCompleted()
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        log.info("Disconnected.")
    }
}
