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
    let scopes = ["openid", "email"]
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
    //                self.updateCurrentAccount(account: currentAccount)
                    observer.onNext(currentAccount)
                    observer.onCompleted()
                } else {
                    self.log.info("Account signed out.")
        //            self.accessToken = ""
        //            self.updateCurrentAccount(account: nil)
                    observer.onNext(nil)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        }
        return observable.asSingle()
    }
    
    func acquireTokenInteractively(webViewParameters: MSALWebviewParameters) {
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount

        applicationContext.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                self.log.error("Could not acquire token: \(error)")
                return
            }

            guard let result = result else {
                self.log.error("Could not acquire token: No result returned")
                return
            }
//            self.accessToken = result.accessToken
            self.log.info("Access token is \(result.accessToken)")
//            self.updateCurrentAccount(account: result.account)
//            self.getContentWithToken()
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount, webViewParameters: MSALWebviewParameters) {
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

            applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    let nsError = error as NSError
                    // interactionRequired means we need to ask the user to sign-in. This usually happens
                    // when the user's Refresh Token is expired or if the user has changed their password
                    // among other possible reasons.
                    if (nsError.domain == MSALErrorDomain) {
                        if (nsError.code == MSALError.interactionRequired.rawValue) {
                            DispatchQueue.main.async {
                                self.acquireTokenInteractively(webViewParameters: webViewParameters)
                            }
                            return
                        }
                    }
                    self.log.warn("Could not acquire token silently: \(error)")
                    return
                }

                guard let result = result else {
                    self.log.warn("Could not acquire token: No result returned")
                    return
                }

//                self.accessToken = result.accessToken
                self.log.info("Refreshed Access token is \(result.accessToken)")
//                self.updateSignOutButton(enabled: true)
//                self.getContentWithToken()
            }
        }
}
