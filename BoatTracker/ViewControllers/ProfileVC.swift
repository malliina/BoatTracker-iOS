//
//  ProfileVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class ProfileVC: UIViewController {
    let log = LoggerFactory.shared.vc(ProfileVC.self)
    
    let feedbackLabel = BoatLabel.build(text: "")
    let logoutButton = BoatButton.create(title: "Logout")
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
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
        navigationItem.title = "Boat"
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.topMargin.equalToSuperview().offset(24)
        }
        logoutButton.addTarget(self, action: #selector(logoutClicked(_:)), for: .touchUpInside)
        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(logoutButton)
        }
    }
    
    @objc func logoutClicked(_ sender: UIButton) {
        try? Keychain.shared.delete()
        delegate?.onToken(token: nil)
        goBack()
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
    
}
