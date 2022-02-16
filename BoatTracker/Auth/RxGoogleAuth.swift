//
//  RxGoogleAuth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 23/12/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//
import Foundation
import RxCocoa
import RxSwift
import GoogleSignIn

class RxGoogleAuth: NSObject {
    let log = LoggerFactory.shared.system(RxGoogleAuth.self)
    static let shared = RxGoogleAuth()
    let google = GIDSignIn.sharedInstance
    var signInConfig: GIDConfiguration? = nil
    
    override init() {
        super.init()
        do {
            signInConfig = GIDConfiguration(clientID: try Credentials.read(key: "GoogleClientId"))
        } catch {
            log.error("Unable to read Google client ID. \(error)")
        }
    }
    
    func signInSilently() {
        google.restorePreviousSignIn()
    }
    
    func obtainToken(from: UIViewController?, restore: Bool) -> Single<UserToken> {
        let subject = ReplaySubject<UserToken>.create(bufferSize: 1)
        if let signInConfig = signInConfig, let from = from, !restore {
            google.signIn(with: signInConfig, presenting: from) { user, error in
                self.toSingle(user: user, error: error, subject: subject)
            }
        } else {
            google.restorePreviousSignIn { user, error in
                self.toSingle(user: user, error: error, subject: subject)
            }
        }
        return subject.asSingle().map { token in
            BoatPrefs.shared.authProvider = .google
            return token
        }
    }
    
    private func toSingle(user: GIDGoogleUser?, error: Error?, subject: ReplaySubject<UserToken>) {
        if let error = error {
            subject.onError(error)
        } else {
            guard let idToken = user?.authentication.idToken else {
                subject.onError(AppError.simple("No ID token in Google sign in response."))
                return
            }
            guard let email = user?.profile?.email else {
                subject.onError(AppError.simple("No email in Google sign in response."))
                return
            }
            log.info("Got email '\(email)' with token '\(idToken)'.")
            subject.onNext(UserToken(email: email, token: AccessToken(idToken)))
            subject.onCompleted()
        }
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return google.handle(url)
    }
}
