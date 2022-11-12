import Foundation
import SwiftUI

struct SocialViewControllerRepresentable: UIViewControllerRepresentable {
    let log = LoggerFactory.shared.view(SocialViewControllerRepresentable.self)
    let provider: AuthProvider
    let image: String
    let lang: Lang
    let onSuccess: (UserToken?) async -> Void
    
    var prefs: BoatPrefs { BoatPrefs.shared }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        SocialViewController(provider: provider, image: image, lang: lang) { token in
            await onSuccess(token)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class SocialViewController: UIViewController {
    let log = LoggerFactory.shared.view(SocialViewController.self)
    let provider: AuthProvider
    let image: String
    let lang: Lang
    let onSuccess: (UserToken?) async -> Void
    
    var prefs: BoatPrefs { BoatPrefs.shared }

    init(provider: AuthProvider, image: String, lang: Lang, onSuccess: @escaping (UserToken?) async -> Void) {
        self.provider = provider
        self.image = image
        self.lang = lang
        self.onSuccess = onSuccess
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let button = BoatButton.create(title: "\(lang.settings.signInWith) \(provider.name)", fontSize: 19)
        button.contentMode = .left
        button.contentHorizontalAlignment = .left
        let logo = UIImage(named: image)!.withRenderingMode(.alwaysOriginal)
        button.setImage(logo, for: .normal)
        button.backgroundColor = BoatColors.shared.almostWhite
        button.addTarget(self, action: #selector(clicked(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(260)
        }
        var conf = UIButton.Configuration.borderless()
        conf.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        conf.imagePadding = 10
        button.configuration = conf
    }

    @objc func clicked(_ sender: UIButton) {
        prefs.authProvider = provider
        prefs.showWelcome = true
        Task {
            let token = await Auth.shared.signIn(from: self, restore: false)
            await onSuccess(token)
        }
    }
}
