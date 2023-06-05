import Foundation
import SwiftUI

struct AuthView: View {
    let log = LoggerFactory.shared.view(AuthView.self)
    @Environment(\.dismiss) var dismiss
    @Binding var welcomeInfo: WelcomeInfo?
    let lang: Lang
    @StateObject var viewModel: AuthVM = AuthVM()
    var settingsLang: SettingsLang { lang.settings }
    var color: BoatColor { BoatColor.shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                SocialButton(provider: .google, image: "LogoGoogle")
                    .padding(.top)
                    .padding(.bottom, margin.medium)
                    .frame(maxWidth: 320)
                SocialButton(provider: .microsoft, image: "LogoMicrosoft")
                    .padding(.bottom, margin.medium)
                    .frame(maxWidth: 320)
                SocialButton(provider: .apple, image: "LogoApple")
                    .frame(height: 42)
                    .padding(.bottom, margin.medium)
                    .frame(maxWidth: 320)
                Text(settingsLang.signInText)
                    .padding()
                Text(settingsLang.howItWorks)
                    .foregroundColor(color.secondaryText)
                    .frame(alignment: .leading)
                    .padding()
                Text(settingsLang.tokenTextLong)
                    .font(.system(size: 17))
                    .foregroundColor(color.secondaryText)
                    .padding(.horizontal)
                NavigationLink {
                    AttributionsView(info: lang.attributions)
                        .navigationBarTitleDisplayMode(.large)
                } label: {
                    NavLink(title: lang.attributions.title)
                }.padding()
            }
        }
    }
    
    func SocialButton(provider: AuthProvider, image: String) -> some View {
        SocialButtonRepresentable(provider: provider, image: image, lang: lang) { token in
            dismiss()
            // Wait for the dismissal to complete... ?
            await Task.sleep(seconds: 0.5)
            welcomeInfo = await viewModel.showWelcome(token: token, lang: lang)
        }
        .frame(height: 42)
    }
}

struct SocialButtonRepresentable: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    let log = LoggerFactory.shared.view(SocialButtonRepresentable.self)
    let provider: AuthProvider
    let image: String
    let lang: Lang
    let onSuccess: (UserToken?) async -> Void
    
    var prefs: BoatPrefs { BoatPrefs.shared }
    
    typealias UIViewControllerType = UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        let button = SocialButtonView(provider: provider, image: image, prefix: lang.settings.signInWith) {
            if let vc = context.coordinator.vc {
                signIn(from: vc)
            }
        }
        let ctrl = UIHostingController(rootView: button)
        let size = ctrl.view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        ctrl.preferredContentSize = CGSize(width: size.width, height: size.height)
        return ctrl
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.vc = uiViewController
    }
    
    func signIn(from: UIViewController) {
        log.info("Signing in...")
        prefs.authProvider = provider
        prefs.showWelcome = true
        Task {
            let token = await Auth.shared.signIn(from: from, restore: false)
            log.info("Signed in \(token?.email ?? "no email")")
            await onSuccess(token)
        }
    }
    
    class Coordinator {
        var vc: UIViewController? = nil
    }
}

/// Clickhandler requires UIViewController, so still using UIKit for this button
struct SocialButtonView: View {
    let provider: AuthProvider
    let image: String
    let prefix: String
    let onClick: () -> Void
    var color: BoatColor { BoatColor.shared }
    var body: some View {
        Button {
            onClick()
        } label: {
            HStack(alignment: .center, spacing: 5.0) {
                Image(image)
                    .padding(.leading, 10.0)
                Text("\(prefix) \(provider.name)")
                    .foregroundColor(.black)
                    .padding(.all, 10.0)
                Spacer()
            }
        }
        .background(color.almostWhite)
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.bottom)
    }
}
