//
//  BoatSwitch.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 07/10/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

// UISwitch that hides the crazy addTarget API
class BoatSwitch: UISwitch {
    let onClick: (UISwitch) -> Void
    
    init(onClick: @escaping (UISwitch) -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
        addTarget(nil, action: #selector(runOnClick(_:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.onClick = { (s) -> () in () }
        super.init(coder: aDecoder)
    }
    
    @objc fileprivate func runOnClick(_ uiSwitch: UISwitch) {
        onClick(uiSwitch)
    }
}
