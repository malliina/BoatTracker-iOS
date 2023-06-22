import Foundation
import SwiftUI
import MapboxMaps

struct WelcomeInfo: Identifiable {
    let boatToken: String
    let lang: SettingsLang
    
    var id: String { boatToken }
}

struct MainMapView<T>: View where T: MapViewModelLike {
    let log = LoggerFactory.shared.view(MainMapView.self)
    
    @EnvironmentObject var viewModel: T
    
    @State var welcomeInfo: WelcomeInfo? = nil
    @State var authInfo: Lang? = nil
    @State var profileInfo: ProfileInfo? = nil
    @State var tapResult: Tapped? = nil
    @State var showPopover: Bool = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                MapViewRepresentable(
                    styleUri: $viewModel.styleUri,
                    tapped: $tapResult,
                    mapMode: $viewModel.mapMode,
                    coords: viewModel.coordsPublisher,
                    vessels: viewModel.vesselsPublisher,
                    commands: viewModel.commands
                )
                .ignoresSafeArea()
                if !viewModel.isProfileButtonHidden {
                    MapButtonView(imageResource: "SettingsSlider") {
                        guard let lang = viewModel.settings.lang else { return }
                        if let user = viewModel.latestToken {
                            profileInfo = ProfileInfo(user: user, current: viewModel.latestTrack, lang: lang)
                        } else {
                            authInfo = lang
                        }
                    }
                    .offset(x: 16, y: 16)
                    .opacity(0.6)
                }
                if !viewModel.isFollowButtonHidden {
                    MapButtonView(imageResource: "LocationArrow") {
                        viewModel.toggleFollow()
                    }
                    .offset(x: 16, y: 60)
                    .opacity(viewModel.mapMode == .follow ? 0.3 : 0.6)
                }
            }
        }
        .sheet(item: $welcomeInfo) { info in
            NavigationView {
                WelcomeView(lang: info.lang, token: info.boatToken)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(info.lang.welcome)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {
                                welcomeInfo = nil
                            } label: {
                                Text(info.lang.done)
                            }
                        }
                    }
            }
        }
        .sheet(item: $profileInfo) { info in
            NavigationView {
                ProfileView<ProfileVM>(info: info)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(info.lang.appName)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button {
                                profileInfo = nil
                            } label: {
                                Text(info.lang.map)
                            }
                        }
                    }
            }
        }
        .sheet(item: $authInfo) { info in
            NavigationView {
                AuthView(welcomeInfo: $welcomeInfo, lang: info)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(info.settings.signIn)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {
                                authInfo = nil
                            } label: {
                                Text(info.settings.cancel)
                            }
                        }
                    }
            }
        }
        .background {
            if let lang = viewModel.settings.lang,
                let specials = viewModel.settings.languages?.finnish.specialWords {
                TappedRepresentable(lang: lang, finnishWords: specials, tapped: $tapResult)
            }
            
        }
    }
}

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        ForEach(["iPhone 12 mini", "iPad Pro (11-inch) (3rd generation)"], id: \.self) { deviceName in
//            MainMapView(viewModel: PreviewMapViewModel())
//                .previewDevice(PreviewDevice(rawValue: deviceName))
//                .previewDisplayName(deviceName)
//        }
//    }
//}
