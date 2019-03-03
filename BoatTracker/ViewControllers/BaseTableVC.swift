//
//  BaseTableVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 21/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class BaseTableVC: UITableViewController {
    var settings: UserSettings { return UserSettings.shared }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Removes separators when there are no more rows
        tableView.tableFooterView = UIView()
    }
}
