import Foundation
import SwiftUI
import Combine

struct TokensLang {
    let notificationsText, notifications, boat, boats, token, tokenText, renameBoat, newName, failText, cancel: String
    
    static func build(lang: Lang) -> TokensLang {
        let settings = lang.settings
        return TokensLang(notificationsText: settings.notificationsText, notifications: settings.notifications, boat: settings.boat, boats: lang.track.boats, token: settings.token, tokenText: settings.tokenText, renameBoat: settings.renameBoat, newName: settings.newName, failText: lang.messages.failedToLoadProfile, cancel: settings.cancel)
    }
}

struct BoatTokensView<T>: View where T: BoatTokensProtocol {
    let log = LoggerFactory.shared.vc(BoatTokensView.self)
    let spacing: CGFloat = 12
    let lang: TokensLang
    @ObservedObject var vm: T
    
    @State var rename: Boat? = nil
    @State var newName: String = ""
    var renamePresented: Binding<Bool> {
        Binding(get: { rename != nil }, set: { _ in () })
    }
    
    var body: some View {
        BoatList {
            Section {
                Toggle(lang.notifications, isOn: $vm.notificationsEnabled)
            } header: {
                Spacer().frame(height: 8)
            } footer: {
                Text(lang.notificationsText)
                    .font(.system(size: 16))
                    .foregroundColor(color.secondaryText)
            }
            Section {
                if let boats = vm.userProfile?.boats {
                    ForEach(boats) { boat in
                        Button {
                            rename = boat
                        } label: {
                            HStack {
                                Spacer()
                                StatView(label: lang.boat, value: boat.name, style: .large)
                                Spacer()
                                StatView(label: lang.token, value: boat.token, style: .large)
                                Spacer()
                            }
                        }
                    }
                }
            } footer: {
                Text(lang.tokenText)
                    .font(.system(size: 16))
                    .foregroundColor(color.secondaryText)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.boats)
        .sheet(item: $rename) { boat in
            EditDialog(navTitle: lang.renameBoat, title: lang.renameBoat, message: boat.name.name, initialValue: "", ctaTitle: lang.renameBoat, cancel: lang.cancel) { newName in
                await vm.rename(boat: boat, newName: newName)
            }
        }
        .task {
            await vm.load()
        }
    }
}

struct BoatTokensPreview: PreviewProvider {
    class PreviewsVM: BoatTokensProtocol {
        var notificationsEnabled: Bool = false
        var userProfile: UserProfile? = UserProfile(id: 1, username: Username("Jack"), email: "a@b.com", language: Language.en, boats: [Boat(id: 1, name: BoatName("Titanic"), token: "token123", addedMillis: 1)], addedMillis: 1)
        func load() async { }
        func rename(boat: Boat, newName: String) async { }
    }
    static var previews: some View {
        Group {
            BoatTokensView(lang: TokensLang.build(lang: lang), vm: PreviewsVM())
        }
    }
}

