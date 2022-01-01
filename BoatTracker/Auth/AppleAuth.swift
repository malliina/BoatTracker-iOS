//
//  AppleAuth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 25.12.2021.
//  Copyright © 2021 Michael Skogberg. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AuthenticationServices

class AppleAuth: NSObject {
    let log = LoggerFactory.shared.system(AppleAuth.self)
    static let shared = AppleAuth()
    
    var from: UIViewController? = nil
    
    private var subject = ReplaySubject<UserToken?>.create(bufferSize: 1)
    
    func obtainToken(from: UIViewController?, restore: Bool) -> Single<UserToken?> {
        return signInSilently().map { $0 }.catch { err in
            self.log.info("Failed to obtain token silently. \(err)")
            if let from = from {
                return self.signInInteractive(from: from)
            } else {
                return Single.just(nil)
            }
        }
    }
    
    func signInSilently() -> Single<UserToken> {
        do {
            let latest = try Keychain.shared.readToken()
            return Backend.shared.http.obtainValidToken(token: latest).map { res in
                self.log.info("Obtained Apple token for '\(res.email)'.")
                return UserToken(email: res.email, token: res.idToken)
            }
        } catch {
            return Single.error(error)
        }
    }
    
    func signInInteractive(from: UIViewController) -> Single<UserToken?> {
        subject = ReplaySubject<UserToken?>.create(bufferSize: 1)
        self.from = from
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        log.info("Attempting to login...")
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        onUiThread {
            authorizationController.delegate = self
            self.log.info("Installing presentation delegate...")
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        return subject.asSingle()
    }
    
    func signOut(from: UIViewController) {
        
    }
    
    func onUiThread(_ f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: f)
    }
}

extension AppleAuth: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let idCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return subject.onError(AppError.simple("Credential is not an ASAuthorizationAppleIDCredential. \(authorization.credential)"))
        }
        guard let idTokenData = idCredential.identityToken else {
            return subject.onError(AppError.simple("No identity token. \(idCredential)"))
        }
        guard let idToken = String(data: idTokenData, encoding: .utf8) else {
            return subject.onError(AppError.simple("ID token is not a string. \(idCredential)"))
        }
//        guard let email = idCredential.email else {
//            let givenName = idCredential.fullName?.givenName ?? "unknown"
//            return subject.onError(AppError.simple("No email in credential. Given name \(givenName). Token was '\(idToken)'. \(idCredential)"))
//        }
        guard let authCodeData = idCredential.authorizationCode, let authCodeStr = String(data: authCodeData, encoding: .utf8) else {
            return subject.onError(AppError.simple("No auth code string. \(idCredential)"))
        }
        let authCode = AuthorizationCode(authCodeStr)
        log.info("Auth complete, authorization code '\(authCode)' token '\(idToken)'.")
        let _ = Backend.shared.http.register(code: authCode).subscribe { e in
            switch(e) {
            case .success(let res):
                self.log.info("Obtained server token for \(res.email) from backend.")
//                try? Keychain.shared.save(token: res.idToken)
                self.subject.onNext(UserToken(email: res.email, token: res.idToken))
                self.subject.onCompleted()
            case .failure(let err):
                self.subject.onError(err)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        log.info("Auth error \(error)")
        subject.onError(error)
    }
}

extension AppleAuth: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return from!.view.window!
    }
}
