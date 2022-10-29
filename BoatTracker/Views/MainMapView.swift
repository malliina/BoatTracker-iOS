import Foundation
import SwiftUI

struct WelcomeInfo: Identifiable {
    let boatToken: String
    let lang: SettingsLang
    
    var id: String { boatToken }
}

class NoopDelegate: WelcomeDelegate {
    func showWelcome(token: UserToken?) async { }
}

struct MainMapView<T>: View where T: MapViewModelLike {
    let log = LoggerFactory.shared.view(MainMapView.self)
    
    @ObservedObject var viewModel: T
    
    @State var welcomeInfo: WelcomeInfo? = nil
    @State var authInfo: Lang? = nil
    
    init(viewModel: T) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                SwiftUIMapView(styleUri: $viewModel.styleUri)
                    .ignoresSafeArea()
                if !viewModel.isProfileButtonHidden {
                    MapButtonView(imageResource: "SettingsSlider") {
                        if let lang = viewModel.settings.lang {
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
            WelcomeSignedInRepresentable(boatToken: info.boatToken, lang: info.lang)
        }
        .sheet(item: $authInfo) { info in
            AuthVCRepresentable(welcomeInfo: $welcomeInfo, lang: info)
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
