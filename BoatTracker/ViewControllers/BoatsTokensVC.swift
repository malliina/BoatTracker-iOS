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
        tableView?.register(BoatTokenCell.self, forCellReuseIdentifier: BoatTokenCell.identifier)
        loadProfile()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BoatTokenCell.identifier, for: indexPath)
        if let boat = profile?.boats[indexPath.row], let cell = cell as? BoatTokenCell {
            cell.fill(boat: boat.name, token: boat.token)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile?.boats.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let textView = BoatTextView(text: "Add the token to the BoatTracker agent software running in your boat. For more information, see https://www.boat-tracker.com/docs/agent.", font: UIFont.systemFont(ofSize: 16))
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let popup = UIAlertController(title: "Rename Boat", message: "Provide a new name", preferredStyle: .alert)
        popup.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "Rename", style: .default) { (a) in
            guard let textField = (popup.textFields ?? []).headOption(),
                let newName = textField.text, !newName.isEmpty,
                let boat = self.profile?.boats[indexPath.row] else { return }
            let _ = Backend.shared.http.renameBoat(boat: boat.id, newName: BoatName(name: newName)).subscribe{ (single) in
                switch single {
                case .success(let boat):
                    self.loadProfile()
                    self.log.info("Renamed to \(boat.name)")
                case .error(let err):
                    self.log.error("Unable to rename. \(err.describe)")
                }
            }
        }
        popup.addAction(okAction)
        popup.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(popup, animated: true, completion: nil)
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
