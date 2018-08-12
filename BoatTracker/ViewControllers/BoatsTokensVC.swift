//
//  BoatsTokensVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class BoatTokensVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(BoatTokensVC.self)
    let cellKey = "BoatCell"

    var profile: UserProfile? = nil
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Boats"
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: cellKey)
        loadProfile()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath)
        cell.selectionStyle = .none
        if let boat = profile?.boats[indexPath.row] {
            cell.textLabel?.text = boat.token
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let boat = profile?.boats[section] else { return nil }
        return boat.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return profile?.boats.count ?? 0
    }
    
    func loadProfile() {
        let _ = Backend.shared.http.profile().subscribe { (single) in
            self.onUiThread {
                self.onProfile(single)
            }
        }
    }
    
    func onProfile(_ single: SingleEvent<UserProfile>) {
        switch single {
        case .success(let p):
            profile = p
            log.info("Got profile for user \(p.username).")
            tableView.reloadData()
        case .error(let err):
            tableView.backgroundView = feedbackView(text: "Unable to load profile. \(err.describe)")
            log.error("Unable to load profile. \(err.describe)")
        }
    }
}
