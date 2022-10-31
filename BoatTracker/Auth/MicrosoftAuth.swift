import Foundation
import MSAL

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
    
    func obtainToken(from: UIViewController?) async throws -> UserToken {
        let webViewParameters = from.map { vc in
            MSALWebviewParameters(authPresentationViewController: vc)
        }
        let result = try await loadAccount(webViewParameter: webViewParameters)
        if let claims = result.account.accountClaims, let email = claims["email"] as? String, let idToken = result.idToken {
            self.log.info("Email is \(email)")
            return UserToken(email: email, token: AccessToken(idToken))
        } else {
            throw AppError.simple("Unable to extract email and ID token from Microsoft auth response.")
        }
    }
    
    func loadAccount(webViewParameter: MSALWebviewParameters?) async throws -> MSALResult {
        if let account = try await loadCurrentAccount() {
            return try await acquireTokenSilently(account, webViewParameters: webViewParameter)
        } else if let webViewParameter = webViewParameter {
            return try await acquireTokenInteractively(webViewParameters: webViewParameter)
        } else {
            throw AppError.simple("Account signed out and no interaction available.")
        }
    }

    func loadCurrentAccount() async throws -> MSALAccount? {
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
        return try await withCheckedThrowingContinuation { cont in
            applicationContext.getCurrentAccount(with: msalParameters) { (currentAccount, previousAccount, error) in
                if let error = error {
                    self.log.error("Couldn't query current account with error: \(error)")
                    cont.resume(throwing: error)
                }
                if let currentAccount = currentAccount, let username = currentAccount.username, let email = currentAccount.accountClaims?["email"] as? String {
                    self.log.info("Found a signed in account for user \(username) with email \(email). Updating data for that account...")
                    cont.resume(returning: currentAccount)
                } else {
                    self.log.info("Account signed out.")
                    cont.resume(returning: nil)
                }
            }
        }
    }
    
    @MainActor
    func acquireTokenInteractively(webViewParameters: MSALWebviewParameters) async throws -> MSALResult {
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        let result = try await applicationContext.acquireToken(with: parameters)
        if let claims = result.account.accountClaims, let email = claims["email"] {
            self.log.info("Email is \(email)")
        }
        self.log.info("Access token is \(result.accessToken)")
        return result
    }
    
    func acquireTokenSilently(_ account : MSALAccount, webViewParameters: MSALWebviewParameters?) async throws -> MSALResult {
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
        do {
            let result = try await applicationContext.acquireTokenSilent(with: parameters)
            if let claims = result.account.accountClaims, let email = claims["email"] {
                log.info("Email is \(email)")
            }
            return result
        } catch {
            let nsError = error as NSError
            // interactionRequired means we need to ask the user to sign-in. This usually happens
            // when the user's Refresh Token is expired or if the user has changed their password
            // among other possible reasons.
            if (nsError.domain == MSALErrorDomain && nsError.code == MSALError.interactionRequired.rawValue) {
                if let webViewParameters = webViewParameters {
                    return try await acquireTokenInteractively(webViewParameters: webViewParameters)
                } else {
                    throw AppError.simple("Interaction required to complete Microsoft auth, but not in an interactive context.")
                }
            } else {
                log.warn("Could not acquire token silently: \(error)")
                throw error
            }
        }
    }
    
    func signOut(from: UIViewController) async {
        do {
            _ = try await signOutFromAccount(from: from)
            log.info("Signed out from Microsoft.")
        } catch let error {
            log.warn("Failed to sign out from Microsoft. \(error)")
        }
    }
    
    @MainActor
    func signOutFromAccount(from: UIViewController) async throws -> MSALAccount? {
        let params = MSALSignoutParameters(webviewParameters: MSALWebviewParameters(authPresentationViewController: from))
        let account = try await loadCurrentAccount()
        if let account = account {
            try await applicationContext.signout(with: account, signoutParameters: params)
            return account
        } else {
            return nil
        }
    }
}
