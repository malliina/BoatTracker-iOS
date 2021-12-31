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
    
    func obtainToken(from: UIViewController?) -> Single<UserToken?> {
        subject = ReplaySubject<UserToken?>.create(bufferSize: 1)
        self.from = from
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        log.info("Attempting to login...")
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        onUiThread {
            authorizationController.delegate = self
            if from != nil {
                self.log.info("Installing presentation delegate...")
                authorizationController.presentationContextProvider = self
            }
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
        guard let authCodeData = idCredential.authorizationCode, let authCode = String(data: authCodeData, encoding: .utf8) else {
            return subject.onError(AppError.simple("No auth code string. \(idCredential)"))
        }
        log.info("Auth complete, authorization code '\(authCode)' token '\(idToken)'.")
        subject.onNext(UserToken(email: "todo@hmm.com", token: AccessToken(idToken)))
        subject.onCompleted()
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
