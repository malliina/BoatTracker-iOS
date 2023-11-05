import AuthenticationServices
import Foundation

class AppleAuth: NSObject {
  let log = LoggerFactory.shared.system(AppleAuth.self)
  static let shared = AppleAuth()

  var from: UIViewController? = nil

  @Published private var subject: UserToken? = nil
  @Published private var error: Error? = nil

  private var currentNonce: String? = nil
  private var cont: CheckedContinuation<UserToken, Error>? = nil

  func obtainToken(from: UIViewController?, restore: Bool) async throws -> UserToken? {
    do {
      return try await signInSilently()
    } catch let err {
      self.log.info("Failed to obtain token silently. \(err)")
      if let from = from {
        return try await signInInteractive(from: from)
      } else {
        return nil
      }
    }
  }

  func signInSilently() async throws -> UserToken {
    let latest = try Keychain.shared.readToken()
    let res = try await Backend.shared.http.obtainValidToken(token: latest)
    self.log.info("Obtained Apple token for '\(res.email)'.")
    return UserToken(email: res.email, token: res.idToken)
  }

  @MainActor
  func signInInteractive(from: UIViewController) async throws -> UserToken {
    self.from = from
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    let nonce = Randoms.shared.randomNonceString()
    currentNonce = nonce
    request.nonce = Randoms.shared.sha256(nonce)
    request.requestedScopes = [.fullName, .email]
    log.info("Attempting to login...")
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    return try await installPresentation(to: authorizationController)
  }

  @MainActor
  private func installPresentation(to: ASAuthorizationController) async throws -> UserToken {
    to.delegate = self
    self.log.info("Installing presentation delegate...")
    to.presentationContextProvider = self
    return try await withCheckedThrowingContinuation { cont in
      self.cont = cont
      to.performRequests()
    }
  }

  func signOut(from: UIViewController) {

  }
}

extension AppleAuth: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    Task {
      do {
        let userToken = try await authController(didCompleteWithAuthorization: authorization)
        await update(token: userToken)
      } catch {
        await update(error: error)
      }
    }
  }

  private func authController(didCompleteWithAuthorization authorization: ASAuthorization)
    async throws -> UserToken
  {
    guard let nonce = currentNonce else {
      throw AppError.simple("No nonce.")
    }
    guard let idCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      throw AppError.simple(
        "Credential is not an ASAuthorizationAppleIDCredential. \(authorization.credential)")
    }
    guard let idTokenData = idCredential.identityToken else {
      throw AppError.simple("No identity token. \(idCredential)")
    }
    guard let idToken = String(data: idTokenData, encoding: .utf8) else {
      throw AppError.simple("ID token is not a string. \(idCredential)")
    }
    guard let authCodeData = idCredential.authorizationCode,
      let authCodeStr = String(data: authCodeData, encoding: .utf8)
    else {
      throw AppError.simple("ID token is not a string. \(idCredential)")
    }
    let reg = RegisterCode(code: AuthorizationCode(authCodeStr), nonce: nonce)
    log.info("Auth complete, authorization code '\(reg.code)' token '\(idToken)'.")
    let res = try await Backend.shared.http.register(code: reg)
    self.log.info("Obtained server token for \(res.email) from backend.")
    return UserToken(email: res.email, token: res.idToken)
  }

  @MainActor private func update(token: UserToken) {
    subject = token
    cont?.resume(returning: token)
  }

  @MainActor private func update(error: Error) {
    self.error = error
    cont?.resume(throwing: error)
  }

  func authorizationController(
    controller: ASAuthorizationController, didCompleteWithError error: Error
  ) {
    log.info("Auth error \(error)")
    self.error = error
  }
}

extension AppleAuth: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return from!.view.window!
  }
}
