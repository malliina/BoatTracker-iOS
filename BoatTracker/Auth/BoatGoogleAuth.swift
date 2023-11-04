import Foundation
import GoogleSignIn

class BoatGoogleAuth: NSObject {
    let log = LoggerFactory.shared.system(BoatGoogleAuth.self)
    static let shared = BoatGoogleAuth()
    let google = GIDSignIn.sharedInstance
//    var signInConfig: GIDConfiguration? = nil
    
    override init() {
        super.init()
    }
    
    @MainActor
    func signIn(from: UIViewController) async throws -> GIDGoogleUser {
        let result = try await google.signIn(withPresenting: from)
        return result.user
//        google.signIn
//        return try await withCheckedThrowingContinuation { cont in
//            google.signIn(with: conf, presenting: from) { user, error in
//                if let error = error {
//                    cont.resume(throwing: error)
//                } else if let user = user {
//                    cont.resume(returning: user)
//                } else {
//                    cont.resume(throwing: AppError.simple("Failed to sign in."))
//                }
//            }
//        }
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
        if let from = from, !restore {
            return try await signIn(from: from)
        } else {
            return try await signInSilently()
        }
    }
    
    func obtainToken(from: UIViewController?, restore: Bool) async throws -> UserToken {
        let user = try await obtainUser(from: from, restore: restore)
        guard let idToken = user.idToken else {
            throw AppError.simple("No ID token in Google sign in response.")
        }
        guard let email = user.profile?.email else {
            throw AppError.simple("No email in Google sign in response.")
        }
        BoatPrefs.shared.authProvider = .google
        log.info("Got email '\(email)' with token '\(idToken)'.")
        return UserToken(email: email, token: AccessToken(idToken.tokenString))
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        google.handle(url)
    }
}
