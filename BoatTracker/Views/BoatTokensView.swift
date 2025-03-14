import Combine
import Foundation
import SwiftUI

struct TokensLang {
  let appIcon, notificationsText, notifications, boat, boats, token, tokenText, renameBoat, newName,
    failText, cancel: String

  static func build(lang: Lang) -> TokensLang {
    let settings = lang.settings
    return TokensLang(
      appIcon: settings.appIcon, notificationsText: settings.notificationsText,
      notifications: settings.notifications, boat: settings.boat, boats: lang.track.boats,
      token: settings.token, tokenText: settings.tokenText, renameBoat: settings.renameBoat,
      newName: settings.newName, failText: lang.messages.failedToLoadProfile,
      cancel: settings.cancel)
  }
}

struct IconImage: View {
  let iconName: String
  let isSelected: Bool

  var body: some View {
    Label {
      Text(iconName)
    } icon: {
      Image(uiImage: UIImage(named: iconName) ?? UIImage())
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(minHeight: 64, maxHeight: isSelected ? 96 : 64)
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
    .labelStyle(.iconOnly)
  }
}

struct BoatTokensView<T>: View where T: BoatTokensProtocol {
  let log = LoggerFactory.shared.vc(BoatTokensView.self)
  let spacing: CGFloat = 12
  let lang: TokensLang
  @EnvironmentObject var vm: T

  @State var rename: Boat? = nil
  @State var newName: String = ""
  var renamePresented: Binding<Bool> {
    Binding(get: { rename != nil }, set: { _ in () })
  }

  var body: some View {
    ScrollView {
      Button {
        Task {
          do {
            try await BoatLiveActivities.shared.startLiveActivity()
            log.info("Started live activity!")
          } catch {
            log.error("Failed to start live activity \(error)")
          }
          
        }
        
      } label: {
        Text("Live activity")
      }

      Text(lang.appIcon)
        .padding(.bottom)
      HStack {
        ForEach(["AppIcon", "CarMapAppIcon"], id: \.self) { icon in
          Button {
            Task {
              await vm.changeAppIcon(to: icon)
            }
          } label: {
            IconImage(iconName: icon, isSelected: vm.appIcon == icon)
          }
        }
      }
      .padding(.vertical)
      Toggle(lang.notifications, isOn: $vm.notificationsEnabled)
        .padding(.horizontal)
      Text(lang.notificationsText)
        .font(.system(size: 16))
        .foregroundColor(color.secondaryText)
        .padding(.horizontal)
        .padding(.bottom)
      Text(lang.renameBoat)
        .padding(.bottom)
      if let boats = vm.userProfile?.boats {
        ForEach(boats) { boat in
          Button {
            rename = boat
          } label: {
            HStack(spacing: 30) {
              StatView(label: lang.boat, value: boat.name, style: .large)
                .frame(maxWidth: .infinity)
              StatView(label: lang.token, value: boat.token, style: .large)
                .frame(maxWidth: .infinity)
            }.frame(maxWidth: 600)
              .padding(.bottom)
          }
        }.padding(.horizontal)
      }
      Text(lang.tokenText)
        .font(.system(size: 16))
        .foregroundColor(color.secondaryText)
        .padding(.horizontal)
    }
    .navigationBarTitleDisplayMode(.large)
    .navigationTitle(lang.boats)
    .sheet(item: $rename) { boat in
      EditDialog(
        navTitle: lang.renameBoat, title: lang.renameBoat, message: boat.name.name,
        initialValue: "", ctaTitle: lang.renameBoat, cancel: lang.cancel
      ) { newName in
        await vm.rename(boat: boat, newName: newName)
      }
    }
    .task {
      await vm.load()
    }
  }
}

struct BoatTokensPreview: BoatPreviewProvider, PreviewProvider {
  class PreviewsVM: BoatTokensProtocol {
    var appIcon: String = BoatTokensVM.defaultAppIcon
    var notificationsEnabled: Bool = false
    var userProfile: UserProfile? = UserProfile(
      id: 1, username: Username("Jack"), email: "a@b.com", language: Language.en,
      boats: [
        Boat(id: 1, name: BoatName("Titanic"), token: "token123", addedMillis: 1),
        Boat(id: 2, name: BoatName("Silja Serenade"), token: "token124", addedMillis: 2),
      ], addedMillis: 1)
    func load() async {}
    func rename(boat: Boat, newName: String) async {}
    func changeAppIcon(to: String) async {}
  }
  static var preview: some View {
    BoatTokensView<PreviewsVM>(lang: TokensLang.build(lang: lang))
      .environmentObject(PreviewsVM())
      .previewDevice("iPhone 13 mini")
  }
}
