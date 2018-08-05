//
//  BoatButton.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class BoatButton {
    static func create(title: String, color: UIColor = UIColor.black, fontSize: CGFloat = 24) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 18
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        button.setTitleColor(color, for: .normal)
        return button
    }
    
    static func secondary(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(.blue, for: .normal)
        return button
    }
    
    static func nav(title: String) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.layer.cornerRadius = 18
        button.setTitleColor(BoatColors.shared.buttonText, for: .normal)
        button.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        return button
    }
    
    static func map(icon: UIImage) -> UIButton {
        let button = MapButton()
        button.setImage(icon, for: .normal)
        button.backgroundColor = .white
        button.alpha = MapButton.selectedAlpha
        return button
    }
}

// https://stackoverflow.com/a/46256731
class MapButton: UIButton {
    static let selectedAlpha: CGFloat = 0.6
    static let deselectedAlpha: CGFloat = 0.3

    let defaultBackground = UIColor.white
    let highlightedBackground = UIColor.white.withAlphaComponent(0.5)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        layer.borderWidth = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 2, height: 2)
    }
    
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackground : defaultBackground
        }
    }
}
