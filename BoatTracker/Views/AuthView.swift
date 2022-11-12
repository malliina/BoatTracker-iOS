import Foundation
import SwiftUI

struct AuthView: View {
    let log = LoggerFactory.shared.view(AuthView.self)
    @Environment(\.dismiss) var dismiss
    @Binding var welcomeInfo: WelcomeInfo?
    let lang: Lang
    let viewModel: AuthVM
    var settingsLang: SettingsLang { lang.settings }
    var color: BoatColor { BoatColor.shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SocialButton(provider: .google, image: "LogoGoogle")
                    .padding(.top)
                    .padding(.bottom, 12)
                SocialButton(provider: .microsoft, image: "LogoMicrosoft")
                    .padding(.bottom, 12)
                SocialButton(provider: .apple, image: "LogoApple")
                    .frame(height: 42)
                    .padding(.bottom, 12)
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
                    AttributionsRepresentable(info: lang.attributions)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.attributions.title)
                } label: {
                    HStack {
                        Text(lang.attributions.title)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }.padding()
            }
        }
    }

    func SocialButton(provider: AuthProvider, image: String) -> some View {
        SocialViewControllerRepresentable(provider: provider, image: image, lang: lang) { token in
            dismiss()
            // Wait for the dismissal to complete... ?
            await Task.sleep(seconds: 0.5)
            welcomeInfo = await viewModel.showWelcome(token: token, lang: lang)
        }
        .frame(height: 42)
    }
}

//struct SocialButton: View {
//    let provider: AuthProvider
//    let image: String
//    let prefix: String
//    let onClick: () -> Void
//    var color: BoatColor { BoatColor.shared }
//    var body: some View {
//        Button {
//            onClick()
//        } label: {
//            HStack(alignment: .center, spacing: 5.0) {
//                Image(image)
//                    .padding(.leading, 10.0)
//                Text("\(prefix) \(provider.name)")
//                    .foregroundColor(.black)
//                    .padding(.all, 10.0)
//                Spacer()
//            }
//        }
//        .background(color.almostWhite)
//        .cornerRadius(14)
//        .padding(.horizontal)
//        .padding(.bottom)
//    }
//}
