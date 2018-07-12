//
//  AuthVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

protocol TokenDelegate {
    func onToken(token: AccessToken?)
}

class AuthVC: UIViewController {
    let log = LoggerFactory.shared.vc(AuthVC.self)
    
    let demoLabel = BoatLabel.build(text: "Enter token", alignment: .center)
    let tokenField = BoatTextField.with(placeholder: "token", keyboardAppearance: .default, isPassword: true)
    let feedbackLabel = BoatLabel.build(text: "")
    let submitButton = BoatButton.create(title: "Submit")
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
        navigationItem.title = "Sign In"
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(demoLabel)
        demoLabel.textColor = .black
        demoLabel.snp.makeConstraints { (make) in
            make.centerX.leadingMargin.trailingMargin.equalToSuperview()
            make.topMargin.equalToSuperview().offset(24)
        }
        view.addSubview(tokenField)
        tokenField.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(demoLabel.snp.bottom).offset(16)
        }
        view.addSubview(feedbackLabel)
        feedbackLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(tokenField.snp.bottom).offset(16)
        }
        view.addSubview(submitButton)
        submitButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(feedbackLabel.snp.bottom).offset(16)
        }
        submitButton.addTarget(self, action: #selector(submitClicked(_:)), for: .touchUpInside)
        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(submitButton)
        }
    }
    
    @objc func submitClicked(_ sender: UIButton) {
        guard let tokenStr = tokenField.text, tokenStr != "" else { return }
        let token = AccessToken(token: tokenStr)
        let http = BoatHttpClient(bearerToken: token)
        showIndicator(on: submitButton, indicator: activityIndicator)
        let _ = http.pingAuth().subscribe { (event) in
            guard !event.isCompleted else { return }
            self.onUiThread {
                self.hideIndicator(on: self.submitButton, indicator: self.activityIndicator)
                if let _ = event.element {
                    do {
                        try Keychain.shared.use(token: token)
                        self.delegate?.onToken(token: token)
                        self.goBack()
                    } catch {
                        self.log.error("Failed to save token \(error)")
                        self.feedbackLabel.text = "Unable to save token."
                    }
                }
                if let error = event.error {
                    self.feedbackLabel.text = "Invalid token."
                    self.log.error("Invalid token \(error)")
                }
            }
        }
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }

}
