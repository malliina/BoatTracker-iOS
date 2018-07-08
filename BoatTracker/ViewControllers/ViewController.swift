//
//  ViewController.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    let helloLabel = BoatLabel.build(text: "Hello, world!")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(helloLabel)
        helloLabel.textColor = .red
        helloLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.centerX.centerY.equalToSuperview()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

