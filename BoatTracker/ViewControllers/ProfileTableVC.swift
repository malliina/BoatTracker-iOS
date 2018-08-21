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
    let infoIdentifier = "InfoCell"
    let logoutIdentifier = "LogoutCell"
    
    var delegate: TokenDelegate? = nil
    var tracksDelegate: TracksDelegate? = nil
    var current: TrackName? = nil
    let user: UserToken
    
    var summary: TrackSummary? = nil
    var showAll: Bool = false
    
    init(tracksDelegate: TracksDelegate, current: TrackName?, user: UserToken) {
        self.tracksDelegate = tracksDelegate
        self.current = current
        self.user = user
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
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: infoIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: logoutIdentifier)
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
            case 2: initAttributionsCell(cell: cell)
            case 3: initLogoutCells(cell: cell, indexPath: indexPath)
            default:
                ()
            }
            
        } else {
            switch indexPath.section {
            case 0: initBoatsCell(cell: cell)
            case 1: initAttributionsCell(cell: cell)
            case 2: initLogoutCells(cell: cell, indexPath: indexPath)
            default: ()
            }
        }
        return cell
    }
    
    func initBoatsCell(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "Boats"
    }
    
    func initAttributionsCell(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "Attributions"
    }
    
    func initLogoutCells(cell: UITableViewCell, indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            if let label = cell.textLabel {
                label.text = "Signed in as \(user.email)"
                label.textAlignment = .center
                label.textColor = .lightGray
            }
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case 1:
            initLogout(cell: cell)
        default:
            ()
        }
    }
    
    func initLogout(cell: UITableViewCell) {
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
        case 2:
            nav(to: AttributionsVC())
        case 3:
            switch indexPath.row {
            case 1: logout()
            default: ()
            }
        default: ()
        }
    }
    
    func didSelectLimited(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            nav(to: BoatTokensVC())
        case 1:
            nav(to: AttributionsVC())
        case 2:
            switch indexPath.row {
            case 1: logout()
            default: ()
            }
        default: ()
        }
    }
    
    func logout() {
        GoogleAuth.shared.signOut()
        delegate?.onToken(token: nil)
        goBack()
    }
    
    func cellIdentifier(indexPath: IndexPath) -> String {
        if showAll {
            switch indexPath.section {
            case 0:
                return TrackSummaryCell.identifier
            case 3:
                switch indexPath.row {
                case 0: return infoIdentifier
                case 1: return logoutIdentifier
                default: return basicCellIdentifier
                }
            default:
                return basicCellIdentifier
            }
        } else {
            switch indexPath.section {
            case 0:
                return basicCellIdentifier
            case 1:
                return basicCellIdentifier
            case 2:
                switch indexPath.row {
                case 0: return infoIdentifier
                case 1: return logoutIdentifier
                default: return basicCellIdentifier
                }
            default:
                return basicCellIdentifier
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showAll {
            switch section {
            case 0: return 1
            case 1: return 2
            case 2: return 1
            case 3: return 2
            default: return 0
            }
        } else {
            switch section {
            case 0: return 1
            case 1: return 1
            case 2: return 2
            default: return 0
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return showAll ? 4 : 3
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
