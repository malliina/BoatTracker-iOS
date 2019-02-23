//
//  WelcomeSignedIn.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 24/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class WelcomeSignedIn: UIViewController {
    let welcomeLabel = BoatLabel.build()
    let tokenLabel: UILabel
    let laterLabel = BoatLabel.build()
    let spacing = 16
    let lang: SettingsLang
    
    init(boatToken: String, lang: SettingsLang) {
        self.lang = lang
        tokenLabel = BoatLabel.build(text: boatToken, textColor: BoatColors.shared.secondaryText)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = lang.welcome
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClicked(_:)))
        view.backgroundColor = colors.backgroundColor
        view.addSubview(welcomeLabel)
        welcomeLabel.text = lang.welcomeText
        welcomeLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.centerX.centerY.equalToSuperview()
        }
        view.addSubview(tokenLabel)
        tokenLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(welcomeLabel.snp.bottom).offset(spacing)
        }
        view.addSubview(laterLabel)
        laterLabel.text = lang.laterText
        laterLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(tokenLabel.snp.bottom).offset(spacing)
        }
    }
    
    @objc func doneClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
