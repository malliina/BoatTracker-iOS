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
    static func build(text: String, alignment: NSTextAlignment = .center, numberOfLines: Int = 1, fontSize: CGFloat = 17, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        label.font = label.font.withSize(fontSize)
        label.textColor = textColor
        return label
    }
}
