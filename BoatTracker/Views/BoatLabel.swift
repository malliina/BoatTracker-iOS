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
    static func smallSubtitle(numberOfLines: Int = 1) -> UILabel {
        let label = smallTitle(textColor: .darkGray, numberOfLines: numberOfLines)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }
    
    static func smallTitle(textColor: UIColor = .black, numberOfLines: Int = 1) -> UILabel {
        build(text: "", alignment: .left, numberOfLines: numberOfLines, fontSize: 12, textColor: textColor)
    }
    
    static func centeredTitle() -> UILabel {
        build(text: "", numberOfLines: 1, fontSize: 16)
    }
    
    static func smallCenteredTitle() -> UILabel {
        build(text: "", alignment: .center, numberOfLines: 1, fontSize: 12)
    }
    
    static func build(text: String = "", alignment: NSTextAlignment = .center, numberOfLines: Int = 0, fontSize: CGFloat = 17, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        label.font = label.font.withSize(fontSize)
        label.textColor = textColor
        return label
    }
}
