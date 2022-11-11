import Foundation
import SwiftUI

struct AuthView: View {
    let lang: Lang
    let viewModel: AuthVM
    var settingsLang: SettingsLang { lang.settings }
    var color: BoatColor { BoatColor.shared }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SocialButton(provider: .google, image: "LogoGoogle")
                SocialButton(provider: .microsoft, image: "LogoMicrosoft")
                SocialButton(provider: .apple, image: "LogoApple")
                Text(settingsLang.signInText)
                    .padding()
                Text(settingsLang.howItWorks)
                    .foregroundColor(color.secondaryText)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding()
                Text(settingsLang.tokenTextLong)
                    .font(.system(size: 17))
                    .foregroundColor(color.secondaryText)
                    .padding(.horizontal)
            }.padding()
        }
    }

    func SocialButton(provider: AuthProvider, image: String) -> some View {
        Button {
            viewModel.clicked(provider: provider)
        } label: {
            HStack(alignment: .center, spacing: 5.0) {
                Image(image)
                    .padding(.leading, 10.0)
                Text("\(lang.settings.signInWith) \(provider.name)")
                    .foregroundColor(.black)
                    .padding(.all, 10.0)
                Spacer()
            }
        }
        .background(BoatColor.shared.almostWhite)
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.bottom)
    }
}
