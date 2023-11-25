import Foundation
import GoogleSignIn

class BoatGoogleAuth: NSObject {
  let log = LoggerFactory.shared.system(BoatGoogleAuth.self)
  static let shared = BoatGoogleAuth()
  let google = GIDSignIn.sharedInstance

  @MainActor
  func signIn(from: UIViewController) async throws -> GIDGoogleUser {
    let result = try await google.signIn(withPresenting: from)
    return result.user
  }

  func signInSilently() async throws -> GIDGoogleUser {
    try await google.restorePreviousSignIn()
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
    log.info("Got email '\(email)' with token '\(idToken.tokenString)'.")
    return UserToken(email: email, token: AccessToken(idToken.tokenString))
  }

  func open(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    google.handle(url)
  }
}
