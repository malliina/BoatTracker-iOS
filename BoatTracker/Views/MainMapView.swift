import Foundation
import SwiftUI

struct WelcomeInfo: Identifiable {
    let boatToken: String
    let lang: SettingsLang
    
    var id: String { boatToken }
}

class NoopDelegate: TracksDelegate {
    func onTrack(_ track: TrackName) {
        
    }
}

struct MainMapView<T>: View where T: MapViewModelLike {
    let log = LoggerFactory.shared.view(MainMapView.self)
    
    @ObservedObject var viewModel: T
    
    @State var welcomeInfo: WelcomeInfo? = nil
    @State var authInfo: Lang? = nil
    @State var profileInfo: ProfileInfo? = nil
    @State var popover: MapPopup? = nil
    @State var showPopover: Bool = false
    
    init(viewModel: T) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                MapViewRepresentable(styleUri: $viewModel.styleUri, latestTrack: $viewModel.latestTrack, popup: $popover, coords: viewModel.coordsPublisher, vessels: viewModel.vesselsPublisher)
                    .ignoresSafeArea()
                if !viewModel.isProfileButtonHidden {
                    MapButtonView(imageResource: "SettingsSlider") {
                        guard let lang = viewModel.settings.lang else { return }
                        if let user = viewModel.latestToken {
                            profileInfo = ProfileInfo(tracksDelegate: NoopDelegate(), user: user, current: viewModel.latestTrack, lang: lang)
                        } else {
                            authInfo = lang
                        }
                    }.offset(x: 16, y: 16)
                }
                if !viewModel.isFollowButtonHidden {
                    MapButtonView(imageResource: "LocationArrow") {
                        log.info("Location tapped")
                        if let settings = viewModel.settings.lang?.settings {
                            welcomeInfo = WelcomeInfo(boatToken: "abc", lang: settings)
                        }
                    }.offset(x: 16, y: 60)
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
