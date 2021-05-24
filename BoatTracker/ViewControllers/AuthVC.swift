//
//  AuthVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import MSAL

protocol WelcomeDelegate {
    func showWelcome(token: UserToken?)
}

class AuthVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(AuthVC.self)
    
    let chooseIdentifier = "ChooseIdentifier"
    let googleIdentifier = "GoogleIdentifier"
    let microsoftIdentifier = "MicrosoftIdentifier"
    let attributionsIdentifier = "AttributionsIdentifier"
    let basicIdentifier = "BasicIdentifier"
    let linkIdentifier = "LinkIdentifier"
    let attributionsIndex = 7
    
    let welcomeDelegate: WelcomeDelegate
    let lang: Lang
    var settingsLang: SettingsLang { lang.settings }
    
    init(welcome: WelcomeDelegate, lang: Lang) {
        self.lang = lang
        self.welcomeDelegate = welcome
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [chooseIdentifier, googleIdentifier, microsoftIdentifier, attributionsIdentifier, basicIdentifier, linkIdentifier].forEach { (identifier) in
            tableView?.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        }
        tableView?.separatorStyle = .none
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.title = lang.settings.signIn
        
        view.backgroundColor = .white
        
        RxGoogleAuth.shared.google.presentingViewController = self
        let _ = Auth.shared.tokens.subscribe(onNext: { token in
            if let token = token {
                self.onToken(token: token)
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier(for: indexPath), for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = lang.profile.chooseIdentityProvider
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
        case 1:
            let googleButton = GIDSignInButton()
            googleButton.style = .wide
            cell.contentView.addSubview(googleButton)
            googleButton.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().inset(12)
                make.leading.equalTo(cell.contentView.snp.leadingMargin)
                make.trailing.equalTo(cell.contentView.snp.trailingMargin)
            }
        case 2:
            let microsoftButton = BoatButton.create(title: "Sign in with Microsoft")
            cell.contentView.addSubview(microsoftButton)
            microsoftButton.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().inset(12)
                make.leading.equalTo(cell.contentView.snp.leadingMargin)
                make.trailing.equalTo(cell.contentView.snp.trailingMargin)
            }
            microsoftButton.addTarget(self, action: #selector(microsoftClicked(_:)), for: .touchUpInside)
        case 3:
            cell.textLabel?.text = settingsLang.signInText
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
        case 4:
            cell.textLabel?.text = settingsLang.howItWorks
            cell.textLabel?.textColor = colors.secondaryText
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
        case 5:
            let textView = BoatTextView(text: lang.settings.tokenTextLong, font: UIFont.systemFont(ofSize: 17))
            textView.textContainer.lineFragmentPadding = 0
            textView.contentInset = .zero
            cell.contentView.addSubview(textView)
            textView.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(cell.contentView.snp.leadingMargin)
                make.trailing.equalTo(cell.contentView.snp.trailingMargin)
            }
            cell.selectionStyle = .none
        case attributionsIndex:
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = lang.attributions.title
        default:
            cell.selectionStyle = .none
            ()
        }
        return cell
    }
    
    @objc func microsoftClicked(_ sender: UIButton) {
        BoatPrefs.shared.authProvider = .microsoft
        Auth.shared.signIn(from: self)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case attributionsIndex: nav(to: AttributionsVC(info: lang.attributions))
        default: ()
        }
    }
    
    func identifier(for row: IndexPath) -> String {
        switch row.row {
        case 0: return chooseIdentifier
        case 1: return googleIdentifier
        case 2: return microsoftIdentifier
        case attributionsIndex: return attributionsIdentifier
        default: return basicIdentifier
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributionsIndex + 1
    }
    
    func onToken(token: UserToken?) {
        dismiss(animated: true) {
            self.welcomeDelegate.showWelcome(token: token)
        }
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
