//
//  BoatColors.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 21/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class BoatColors {
    static let shared = BoatColors()
    
    let blue = UIColor(r: 0, g: 122, b: 255, alpha: 1.0)
    let tealBlue = UIColor(r: 90, g: 200, b: 250, alpha: 1.0)
    let purple = UIColor(r: 88, g: 86, b: 214, alpha: 1.0)
    let almostWhite = UIColor(r: 244, g: 244, b: 244, alpha: 1.0)
    
    var buttonText: UIColor { blue }
    let textColor = UIColor.black
    let secondaryText = UIColor.darkGray
    let logoutBackground = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
    var feedback: UIColor { textColor }
    var backgroundColor: UIColor { .white }
}

class BoatColor {
    static let shared = BoatColor(BoatColors.shared)
    let ref: BoatColors
    init(_ ref: BoatColors) {
        self.ref = ref
    }
    var almostWhite: Color { Color(uiColor: ref.almostWhite) }
    var secondaryText: Color { Color(uiColor: ref.secondaryText) }
    var lightGray: Color { Color(uiColor: .lightGray) }
}

extension UIColor {
    // https://stackoverflow.com/a/33342904
    convenience init(r: Int, g: Int, b: Int, alpha: CGFloat) {
        let redPart: CGFloat = CGFloat(r) / 255
        let greenPart: CGFloat = CGFloat(g) / 255
        let bluePart: CGFloat = CGFloat(b) / 255
        
        self.init(red: redPart, green: greenPart, blue: bluePart, alpha: alpha)
    }
}
