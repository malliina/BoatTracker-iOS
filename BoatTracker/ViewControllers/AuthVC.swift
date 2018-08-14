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

class AuthVC: UIViewController, GIDSignInUIDelegate, TokenDelegate {
    let log = LoggerFactory.shared.vc(AuthVC.self)
    
    let demoLabel = BoatLabel.build(text: "Choose Identity Provider", alignment: .center)
    
    var delegate: TokenDelegate? = nil
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.title = "Sign In"
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(demoLabel)
        demoLabel.textColor = .black
        demoLabel.snp.makeConstraints { (make) in
            make.centerX.leadingMargin.trailingMargin.equalToSuperview()
            make.topMargin.equalToSuperview().offset(24)
        }
        
        GoogleAuth.shared.uiDelegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        let googleButton = GIDSignInButton()
        view.addSubview(googleButton)
        googleButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(demoLabel.snp.bottom).offset(16)
        }
    }
    
    func onToken(token: UserToken?) {
        goBack()
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }

}
