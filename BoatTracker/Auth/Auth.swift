//
//  Auth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 23.5.2021.
//  Copyright © 2021 Michael Skogberg. All rights reserved.
//

import Foundation
import GoogleSignIn
import RxSwift

class Auth {
    static let shared = Auth()
    let log = LoggerFactory.shared.system(Auth.self)
    
    private var prefs: BoatPrefs { BoatPrefs.shared }
    
    private let subject = ReplaySubject<UserToken?>.create(bufferSize: 1)
    var tokens: Observable<UserToken?> { subject }
    
    private var google: RxGoogleAuth { RxGoogleAuth.shared }
    private var microsoft: MicrosoftAuth { MicrosoftAuth.shared }
    
    func signIn(from: UIViewController) {
        signInAny(from: from)
    }
    
    func signInAny(from: UIViewController?) {
        let _ = obtainToken(from: from).subscribe { (event) in
            switch event {
            case .success(let token):
                self.subject.onNext(token)
            case .failure(let err):
                self.log.error("Failed to authenticate: '\(err.describe)'.")
                self.subject.onNext(nil)
            }
        }
    }
    
    func signInSilentlyNow() {
        let _ = signInAny(from: nil)
    }
    
    func signInSilently() -> Single<UserToken?> {
        return obtainToken(from: nil)
    }
    
    func signOut(from: UIViewController) {
        switch prefs.authProvider {
        case .google:
            google.google.signOut()
        case .microsoft:
            microsoft.signOut(from: from)
        case .none:
            log.info("Nothing to sign out from.")
        }
        prefs.authProvider = .none
        subject.onNext(nil)
    }
    
    private func obtainToken(from: UIViewController?) -> Single<UserToken?> {
        switch prefs.authProvider {
        case .google:
            return google.obtainToken(from: from)
        case .microsoft:
            return microsoft.obtainToken(from: from).map { token in
                token
            }
        case .none:
            log.info("No auth provider.")
            return Single.just(nil)
        }
    }
}
