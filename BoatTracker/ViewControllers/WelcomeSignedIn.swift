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
    let welcomeLabel = BoatLabel.build(text: "Add this token to the Boat-Tracker agent software in your boat to save tracks to this app:")
    let tokenLabel: UILabel
    let laterLabel = BoatLabel.build(text: "You can later view this token in the Boats section of the app.")
    let spacing = 16
    
    init(boatToken: String) {
        tokenLabel = BoatLabel.build(text: boatToken, textColor: BoatColors.shared.secondaryText)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Welcome"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClicked(_:)))
        view.backgroundColor = colors.backgroundColor
        view.addSubview(welcomeLabel)
        welcomeLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.centerX.centerY.equalToSuperview()
        }
        view.addSubview(tokenLabel)
        tokenLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(welcomeLabel.snp.bottom).offset(spacing)
        }
        view.addSubview(laterLabel)
        laterLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(tokenLabel.snp.bottom).offset(spacing)
        }
    }
    
    @objc func doneClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
