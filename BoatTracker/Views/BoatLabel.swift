//
//  BoatLabel.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class BoatLabel {
    static func smallSubtitle() -> UILabel {
        return smallTitle(textColor: .darkGray)
    }
    
    static func smallTitle(textColor: UIColor = .black, numberOfLines: Int = 1) -> UILabel {
        return build(text: "", alignment: .left, numberOfLines: numberOfLines, fontSize: 12, textColor: textColor)
    }
    
    static func centeredTitle() -> UILabel {
        return build(text: "", numberOfLines: 1, fontSize: 16)
    }
    
    static func build(text: String, alignment: NSTextAlignment = .center, numberOfLines: Int = 0, fontSize: CGFloat = 17, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        label.font = label.font.withSize(fontSize)
        label.textColor = textColor
        return label
    }
}
