import Foundation
import SwiftUI

struct AuthView: View {
    let lang: Lang
    let viewModel: AuthVM
    
    var body: some View {
        ScrollView {
            VStack {
                SocialButton(provider: .google, image: "LogoGoogle")
                SocialButton(provider: .microsoft, image: "LogoMicrosoft")
                SocialButton(provider: .apple, image: "LogoApple")
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
    }
}
