//
//  BoatTextView.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 25/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class BoatTextView: UITextView {
    init(text: String?, font: UIFont) {
        super.init(frame: CGRect.zero, textContainer: nil)
        self.text = text
        self.font = font
        isScrollEnabled = false
        isEditable = false
        dataDetectorTypes = .link
        textColor = .darkGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
