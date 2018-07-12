//
//  BoatTextField.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class BoatTextField: UITextField, UITextFieldDelegate {
    var placeholderText: String? {
        get { return placeholder }
//        set(newPlaceholder) { attributedPlaceholder = NSAttributedString(string: newPlaceholder ?? "", attributes: [NSAttributedStringKey.foregroundColor: PicsColors.placeholder]) }
        set(newPlaceholder) { attributedPlaceholder = NSAttributedString(string: newPlaceholder ?? "") }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    static func with(placeholder: String, keyboardAppearance: UIKeyboardAppearance = .dark, isPassword: Bool = false) -> BoatTextField {
        let field = BoatTextField()
        field.placeholderText = placeholder
        field.isSecureTextEntry = isPassword
        field.keyboardAppearance = keyboardAppearance
        return field
    }
    
    fileprivate func initUI() {
        delegate = self
//        backgroundColor = PicsColors.inputBackground
//        textColor = PicsColors.inputText
        borderStyle = .roundedRect
        font = UIFont.systemFont(ofSize: 28)
        autocorrectionType = .no
        autocapitalizationType = .none
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
