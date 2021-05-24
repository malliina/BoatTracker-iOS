//
//  Microsoftauth.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 13.5.2021.
//  Copyright © 2021 Michael Skogberg. All rights reserved.
//

import Foundation
import MSAL
import RxSwift
import RxCocoa

class MicrosoftAuth {
    let kGraphEndpoint = "https://graph.microsoft.com/"
    let kAuthority = "https://login.microsoftonline.com/common"
    let scopes: [String] = ["email"]
    let clientId = "d55eafcb-e3a5-4ee0-ba5c-03a6c887b6db"
    private let applicationContext: MSALPublicClientApplication
    let log = LoggerFactory.shared.system(MicrosoftAuth.self)
    static let shared = MicrosoftAuth()
    
    init() {
        let authority = try! MSALAADAuthority(url: URL(string: kAuthority)!)
        // redirectUri: The redirect URI of the application. You can pass 'nil' to use the default value, or your custom redirect URI.
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: clientId, redirectUri: nil, authority: authority)
        self.applicationContext = try! MSALPublicClientApplication(configuration: msalConfiguration)
    }
    
    func obtainToken(from: UIViewController?) -> Single<UserToken> {
        let webViewParameters = from.map { vc in
            MSALWebviewParameters(authPresentationViewController: vc)
        }
        return loadAccount(webViewParameter: webViewParameters).flatMap { result in
            if let claims = result.account.accountClaims, let email = claims["email"] as? String, let idToken = result.idToken {
                self.log.info("Email is \(email)")
                return Single.just(UserToken(email: email, token: AccessToken(idToken)))
            } else {
                return Single.error(AppError.simple("Unable to extract email and ID token from Microsoft auth response."))
            }
        }
    }
    
    func loadAccount(webViewParameter: MSALWebviewParameters?) -> Single<MSALResult> {
        return loadCurrentAccount().flatMap { account in
            if let account = account {
                return self.acquireTokenSilently(account, webViewParameters: webViewParameter)
            } else if let webViewParameter = webViewParameter {
                return self.acquireTokenInteractively(webViewParameters: webViewParameter)
            } else {
                return Single.error(AppError.simple("Account signed out and no interaction available."))
            }
        }
    }

    func loadCurrentAccount() -> Single<MSALAccount?> {
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
        
        let observable = Observable<MSALAccount?>.create { (observer) -> Disposable in
            self.applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
                if let error = error {
                    self.log.error("Couldn't query current account with error: \(error)")
                    observer.onError(error)
                }
                if let currentAccount = currentAccount {
                    self.log.info("Found a signed in account \(String(describing: currentAccount.username)). Updating data for that account...")
                    observer.onNext(currentAccount)
                    observer.onCompleted()
                } else {
                    self.log.info("Account signed out.")
                    observer.onNext(nil)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        }
        return observable.asSingle()
    }
    
    func acquireTokenInteractively(webViewParameters: MSALWebviewParameters) -> Single<MSALResult> {
        let observable = Observable<MSALResult>.create { (observer) -> Disposable in
            self.acquireTokenInteractively(webViewParameters: webViewParameters, with: observer)
            return Disposables.create()
        }
        return observable.asSingle()
    }
    
    private func acquireTokenInteractively(webViewParameters: MSALWebviewParameters, with: AnyObserver<MSALResult>) {
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        self.applicationContext.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                self.log.error("Could not acquire token: \(error)")
                with.onError(error)
            } else if let result = result {
                if let claims = result.account.accountClaims, let email = claims["email"] {
                    self.log.info("Email is \(email)")
                }
                self.log.info("Access token is \(result.accessToken)")
                with.onNext(result)
                with.onCompleted()
            } else {
                self.log.error("Could not acquire token: No result returned")
                with.onError(AppError.simple("No result from Microsoft auth."))
            }
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount, webViewParameters: MSALWebviewParameters?) -> Single<MSALResult> {
            /**

             Acquire a token for an existing account silently

             - forScopes:           Permissions you want included in the access token received
             in the result in the completionBlock. Not all scopes are
             guaranteed to be included in the access token returned.
             - account:             An account object that we retrieved from the application object before that the
             authentication flow will be locked down to.
             - completionBlock:     The completion block that will be called when the authentication
             flow completes, or encounters an error.
             */

            let parameters = MSALSilentTokenParameters(scopes: scopes, account: account)

        let observable = Observable<MSALResult>.create { (observer) -> Disposable in
            self.applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    let nsError = error as NSError
                    // interactionRequired means we need to ask the user to sign-in. This usually happens
                    // when the user's Refresh Token is expired or if the user has changed their password
                    // among other possible reasons.
                    if (nsError.domain == MSALErrorDomain && nsError.code == MSALError.interactionRequired.rawValue) {
                        if let webViewParameters = webViewParameters {
                            DispatchQueue.main.async {
                                self.acquireTokenInteractively(webViewParameters: webViewParameters, with: observer)
                            }
                        } else {
                            observer.onError(AppError.simple("Interaction required to complete Microsoft auth, but not in an interactive context."))
                        }
                    } else {
                        self.log.warn("Could not acquire token silently: \(error)")
                        observer.onError(error)
                    }
                } else {
                    if let result = result {
                        if let claims = result.account.accountClaims, let email = claims["email"] {
                            self.log.info("Email is \(email)")
                        }
                        self.log.info("Refreshed Access token is \(result.accessToken)")
                        observer.onNext(result)
                        observer.onCompleted()
                    } else {
                        self.log.warn("Could not acquire token: No result returned")
                        observer.onError(AppError.simple("No result from silent Microsoft auth."))
                    }
                }
            }
            return Disposables.create()
        }
        return observable.asSingle()
    }
    
    func signOut(from: UIViewController) {
        let _ = signOutFromAccount(from: from).subscribe { account in
            self.log.info("Signed out from Microsoft.")
        } onFailure: { err in
            self.log.warn("Failed to sign out from Microsoft.")
        } onDisposed: {
        }
    }
    
    func signOutFromAccount(from: UIViewController) -> Single<MSALAccount?> {
        let params = MSALSignoutParameters(webviewParameters: MSALWebviewParameters(authPresentationViewController: from))
        return loadCurrentAccount().flatMap { account in
            if let account = account {
                self.applicationContext.signout(with: account, signoutParameters: params) { isOut, error in
                    ()
                }
                return Single.just(account)
            } else {
                return Single.just(nil)
            }
        }
    }
}
