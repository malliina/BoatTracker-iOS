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

protocol TokenDelegate {
    func onToken(token: UserToken?)
}

protocol WelcomeDelegate {
    func showWelcome(token: UserToken?)
}

class AuthVC: BaseTableVC, GIDSignInUIDelegate, TokenDelegate {
    let log = LoggerFactory.shared.vc(AuthVC.self)
    
    let chooseIdentifier = "ChooseIdentifier"
    let googleIdentifier = "GoogleIdentifier"
    let attributionsIdentifier = "AttributionsIdentifier"
    let basicIdentifier = "BasicIdentifier"
    let linkIdentifier = "LinkIdentifier"
    let attributionsIndex = 6
    
    let chooseProvider = BoatLabel.build(text: "Choose Identity Provider", alignment: .center)
    
    var delegate: TokenDelegate? = nil
    let welcomeDelegate: WelcomeDelegate
    
    init(welcome: WelcomeDelegate) {
        self.welcomeDelegate = welcome
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: chooseIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: googleIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: attributionsIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: basicIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: linkIdentifier)
        tableView?.separatorStyle = .none
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.title = "Sign In"
        
        view.backgroundColor = .white
        
        GoogleAuth.shared.uiDelegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier(for: indexPath), for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Choose Identity Provider"
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
            cell.textLabel?.text = "Sign in to view past tracks driven with your boat."
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
        case 3:
            cell.textLabel?.text = "How it works"
            cell.textLabel?.textColor = .darkGray
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
        case 4:
            let textView = BoatTextView(text: "Add the token provided after sign in to the BoatTracker agent software running in your boat. Subsequently, tracks driven with the boat are saved to your account and can be viewed in this app. For agent installation instructions, see https://www.boat-tracker.com/docs/agent.", font: UIFont.systemFont(ofSize: 17))
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
            cell.textLabel?.text = "Attributions"
        default:
            cell.selectionStyle = .none
            ()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case attributionsIndex: nav(to: AttributionsVC())
        default: ()
        }
    }
    
    func identifier(for row: IndexPath) -> String {
        switch row.row {
        case 0: return chooseIdentifier
        case 1: return googleIdentifier
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
