import Foundation
import SwiftUI

struct WelcomeInfo: Identifiable {
    let boatToken: String
    let lang: SettingsLang
    
    var id: String { boatToken }
}

struct MainMapView<T>: View where T: MapViewModelLike {
    let log = LoggerFactory.shared.view(MainMapView.self)
    
    @ObservedObject var viewModel: T
    
    @State var welcomeInfo: WelcomeInfo? = nil
    @State var authInfo: Lang? = nil
    @State var authInfo2: Lang? = nil
    @State var profileInfo: ProfileInfo? = nil
    @State var popover: MapPopup? = nil
    @State var showPopover: Bool = false
    
    init(viewModel: T) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                MapViewRepresentable(styleUri: $viewModel.styleUri, latestTrack: $viewModel.latestTrack, popup: $popover, mapMode: $viewModel.mapMode, coords: viewModel.coordsPublisher, vessels: viewModel.vesselsPublisher, commands: viewModel.commands)
                    .ignoresSafeArea()
                if !viewModel.isProfileButtonHidden {
                    MapButtonView(imageResource: "SettingsSlider") {
                        guard let lang = viewModel.settings.lang else { return }
                        if let user = viewModel.latestToken {
                            profileInfo = ProfileInfo(tracksDelegate: viewModel, user: user, current: viewModel.latestTrack, lang: lang)
                        } else {
                            authInfo = lang
                        }
                    }
                    .offset(x: 16, y: 16)
                    .opacity(0.6)
                }
                if !viewModel.isProfileButtonHidden {
                    MapButtonView(imageResource: "SettingsSlider") {
                        guard let lang = viewModel.settings.lang else { return }
                        authInfo2 = lang
                    }
                    .offset(x: 66, y: 16)
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
                WelcomeSignedInRepresentable(boatToken: info.boatToken, lang: info.lang)
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
        .sheet(item: $authInfo) { info in
            NavigationView {
                AuthVCRepresentable(welcomeInfo: $welcomeInfo, lang: info)
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
        .sheet(item: $profileInfo) { info in
            NavigationView {
                ProfileTableRepresentable(info: info)
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
        .sheet(item: $authInfo2) { info in
            NavigationView {
                AuthView(lang: info, viewModel: AuthVM())
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(info.settings.signIn)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {
                                authInfo2 = nil
                            } label: {
                                Text(info.settings.cancel)
                            }
                        }
                    }
            }
        }
        .background {
            PopupRepresentable(popup: popover)
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
