import Foundation
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
    
    func signIn(conf: GIDConfiguration, from: UIViewController) async throws -> GIDGoogleUser {
        return try await withCheckedThrowingContinuation { cont in
            google.signIn(with: conf, presenting: from) { user, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let user = user {
                    cont.resume(returning: user)
                } else {
                    cont.resume(throwing: AppError.simple("Failed to sign in."))
                }
            }
        }
    }
    
    func signInSilently() async throws -> GIDGoogleUser {
        return try await withCheckedThrowingContinuation { cont in
            google.restorePreviousSignIn { user, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let user = user {
                    cont.resume(returning: user)
                } else {
                    cont.resume(throwing: AppError.simple("Failed to sign in silently."))
                }
            }
        }
    }
    
    func obtainUser(from: UIViewController?, restore: Bool) async throws -> GIDGoogleUser {
        if let signInConfig = signInConfig, let from = from, !restore {
            return try await signIn(conf: signInConfig, from: from)
        } else {
            return try await signInSilently()
        }
    }
    
    func obtainToken(from: UIViewController?, restore: Bool) async throws -> UserToken {
        let user = try await obtainUser(from: from, restore: restore)
        guard let idToken = user.authentication.idToken else {
            throw AppError.simple("No ID token in Google sign in response.")
        }
        guard let email = user.profile?.email else {
            throw AppError.simple("No email in Google sign in response.")
        }
        BoatPrefs.shared.authProvider = .google
        log.info("Got email '\(email)' with token '\(idToken)'.")
        return UserToken(email: email, token: AccessToken(idToken))
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        google.handle(url)
    }
}
