//
//  ProfileTableVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class ProfileTableVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(ProfileTableVC.self)
    
    let basicCellIdentifier = "BasicCell"
    
    var delegate: TokenDelegate? = nil
    var tracksDelegate: TracksDelegate? = nil
    var current: TrackName? = nil
    var summary: TrackSummary? = nil
    var showAll: Bool = false
    
    init(tracksDelegate: TracksDelegate, current: TrackName?) {
        self.tracksDelegate = tracksDelegate
        self.current = current
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Map", style: .plain, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.title = "BoatTracker"
        tableView?.register(TrackSummaryCell.self, forCellReuseIdentifier: TrackSummaryCell.identifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: basicCellIdentifier)
        loadTracks()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier(indexPath: indexPath), for: indexPath)
        if showAll {
            switch indexPath.section {
            case 0:
                cell.selectionStyle = .none
                if let summary = summary, let cell = cell as? TrackSummaryCell {
                    cell.fill(track: summary.track)
                }
            case 1:
                cell.accessoryType = .disclosureIndicator
                switch indexPath.row {
                case 0: cell.textLabel?.text = "Track History"
                case 1: cell.textLabel?.text = "Boats"
                default: ()
                }
            case 2:
                initAttributionsCell(cell: cell)
            case 3:
                initLogoutCell(cell: cell)
                
            default:
                ()
            }
            
        } else {
            switch indexPath.section {
            case 0: initAttributionsCell(cell: cell)
            case 1: initLogoutCell(cell: cell)
            default: ()
            }
        }
        return cell
    }
    
    func initAttributionsCell(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "Attributions"
    }
    
    func initLogoutCell(cell: UITableViewCell) {
        if let label = cell.textLabel {
            label.text = "Logout"
            label.textColor = .red
            label.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if showAll {
            didSelectAsFull(indexPath)
        } else {
            didSelectLimited(indexPath)
        }
    }
    
    func didSelectAsFull(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0: nav(to: TrackListVC(delegate: tracksDelegate))
            case 1: nav(to: BoatTokensVC())
            default: ()
            }
        case 2: nav(to: AttributionsVC())
        case 3: logout()
        default: ()
        }
    }
    
    func didSelectLimited(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 0: nav(to: AttributionsVC())
        case 1: logout()
        default: ()
        }
    }
    
    func logout() {
        GoogleAuth.shared.signOut()
        delegate?.onToken(token: nil)
        goBack()
    }
    
    func nav(to: UIViewController) {
        self.navigationController?.pushViewController(to, animated: true)
    }
    
    func cellIdentifier(indexPath: IndexPath) -> String {
        if showAll {
            switch indexPath.section {
            case 0: return TrackSummaryCell.identifier
            default: return basicCellIdentifier
            }
        } else {
            return basicCellIdentifier
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showAll {
            switch section {
            case 0: return 1
            case 1: return 2
            case 2: return 1
            case 3: return 1
            default: return 0
            }
        } else {
            return 1
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return showAll ? 4 : 2
    }
    
    func loadTracks() {
        let _ = Backend.shared.http.tracks().subscribe { (single) in
            switch single {
            case .success(let ts):
                self.log.info("Got \(ts.count) tracks.")
                self.onUiThread {
                    self.onTracks(ts: ts)
                }
            case .error(let err):
                self.log.error("Unable to load tracks. \(err.describe)")
            }
        }
    }
    
    func onTracks(ts: [TrackSummary]) {
        showAll = !ts.isEmpty
        summary = ts.first(where: { (summary) -> Bool in
            summary.track.trackName == current
        })
        tableView.reloadData()
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
