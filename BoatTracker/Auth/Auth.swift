import Combine
import Foundation

enum AuthState {
  case unknown, unauthenticated
  case authenticated(token: UserToken)
}

class Auth {
  static let shared = Auth()

  let log = LoggerFactory.shared.system(Auth.self)

  private var prefs: BoatPrefs { BoatPrefs.shared }

  @Published var authState: AuthState = .unknown

  var tokens: AnyPublisher<UserToken, Never> {
    $authState.compactMap { state in
      switch state {
      case .authenticated(let token): return token
      default: return nil
      }
    }.removeDuplicates().eraseToAnyPublisher()
  }

  private var google: BoatGoogleAuth { BoatGoogleAuth.shared }
  private var microsoft: MicrosoftAuth { MicrosoftAuth.shared }
  private var apple: AppleAuth { AppleAuth.shared }

  func signIn(from: UIViewController, restore: Bool) async -> UserToken? {
    await signInAny(from: from, restore: restore)
  }

  func signInAny(from: UIViewController?, restore: Bool) async -> UserToken? {
    do {
      let token = try await obtainToken(from: from, restore: restore)
      if let token = token {
        authState = .authenticated(token: token)
      } else {
        authState = .unauthenticated
      }
      return token
    } catch {
      log.error("Failed to authenticate: '\(error.describe)'.")
      authState = .unknown
      return nil
    }
  }

  func signInSilentlyNow() async {
    log.info("Signing in silently")
    _ = await signInAny(from: nil, restore: true)
  }

  func signInSilently() async throws -> UserToken? {
    try await obtainToken(from: nil, restore: true)
  }

  func signOut(from: UIViewController) async {
    switch prefs.authProvider {
    case .google:
      google.google.signOut()
    case .microsoft:
      await microsoft.signOut(from: from)
    case .apple:
      apple.signOut(from: from)
    case .none:
      log.info("Nothing to sign out from.")
    }
    prefs.authProvider = .none
    authState = .unauthenticated
  }

  @MainActor
  private func obtainToken(from: UIViewController?, restore: Bool) async throws
    -> UserToken?
  {
    switch prefs.authProvider {
    case .google:
      return try await google.obtainToken(from: from, restore: restore)
    case .microsoft:
      return try await microsoft.obtainToken(from: from)
    case .apple:
      return try await apple.obtainToken(from: from, restore: restore)
    case .none:
      log.info("No auth provider.")
      return nil
    }
  }
}
