//
//  extensions.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func feedbackView(text: String) -> UIView {
        let feedback = BoatLabel.build(text: text, alignment: .center, numberOfLines: 0)
        let container = UIView()
        container.addSubview(feedback)
        feedback.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        return container
    }
    
    func navigate(to: UIViewController, style: UIModalPresentationStyle = .formSheet) {
        let nav = UINavigationController(rootViewController: to)
        nav.modalPresentationStyle = style
        nav.navigationBar.prefersLargeTitles = true
        present(nav, animated: true, completion: nil)
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func onUiThread(_ f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: f)
    }
    
    func showIndicator(on: UIButton, indicator: UIActivityIndicatorView) {
        animated(view: on) {
            on.isHidden = true
            indicator.startAnimating()
        }
    }
    
    func hideIndicator(on: UIButton, indicator: UIActivityIndicatorView) {
        animated(view: on) {
            on.isHidden = false
            indicator.stopAnimating()
        }
    }
    
    func animated(view: UIView, changes: @escaping () -> Void) {
        UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: changes, completion: nil)
    }
}
