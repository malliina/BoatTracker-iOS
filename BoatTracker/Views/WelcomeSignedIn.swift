import Foundation
import SwiftUI

struct WelcomeView: View {
  let lang: SettingsLang
  let token: String

  var body: some View {
    VStack {
      Spacer()
        .frame(maxHeight: 150)
      Text(lang.welcomeText)
      Text(token)
        .foregroundColor(color.secondaryText)
        .padding(.vertical)
      Text(lang.laterText)
      Spacer()
    }
    .padding(.horizontal)
  }
}
