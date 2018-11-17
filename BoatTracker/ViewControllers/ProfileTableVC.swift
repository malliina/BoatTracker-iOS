//
//  ProfileTableVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

extension ProfileTableVC: BoatSocketDelegate {
    func onCoords(event: CoordsData) {
        onUiThread {
            self.update(stats: event.from)
        }
    }
}

enum ViewState {
    case empty
    case content
    case loading
    case failed
}

class ProfileTableVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(ProfileTableVC.self)
    
    let basicCellIdentifier = "BasicCell"
    let infoIdentifier = "InfoCell"
    let logoutIdentifier = "LogoutCell"
    let noTracksIdentifier = "NoTracksCell"
    
    let delegate: TokenDelegate
    let tracksDelegate: TracksDelegate
    let user: UserToken
    let current: TrackName?
    
    var summary: TrackRef? = nil
    var state: ViewState = .loading
    var isInitial: Bool = false
    
    private var socket: BoatSocket { return Backend.shared.socket }
    
    func update(stats: TrackRef) {
        if let current = current, stats.trackName == current {
            onUiThread {
                self.summary = stats
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
    }
    
    init(tokenDelegate: TokenDelegate, tracksDelegate: TracksDelegate, current: TrackName?, user: UserToken) {
        self.delegate = tokenDelegate
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
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: noTracksIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: basicCellIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: infoIdentifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: logoutIdentifier)
        loadTracks()
        socket.statsDelegate = self
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier(indexPath: indexPath), for: indexPath)
        switch state {
        case .content:
            switch indexPath.section {
            case 0:
                cell.selectionStyle = .none
                if let summary = summary, let cell = cell as? TrackSummaryCell {
                    cell.fill(track: summary)
                }
            case 1:
                cell.accessoryType = .disclosureIndicator
                switch indexPath.row {
                case 0: cell.textLabel?.text = "Graph"
                case 1: cell.textLabel?.text = "Track History"
                case 2: cell.textLabel?.text = "Boats"
                default: ()
                }
            case 2: initAttributionsCell(cell: cell)
            case 3: initLogoutCells(cell: cell, indexPath: indexPath)
            default: ()
            }
        case .empty:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0: initNoTracksCell(cell: cell)
                case 1: initBoatsCell(cell: cell)
                default: ()
                }
            case 1: initAttributionsCell(cell: cell)
            case 2: initLogoutCells(cell: cell, indexPath: indexPath)
            default: ()
            }
        default: ()
        }
        return cell
    }
    
    func initNoTracksCell(cell: UITableViewCell) {
        cell.textLabel?.text = "No saved tracks"
        cell.textLabel?.textColor = colors.secondaryText
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
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
        switch state {
        case .content: didSelectAsFull(indexPath)
        case .empty: didSelectLimited(indexPath)
        default: ()
        }
    }
    
    func didSelectAsFull(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                guard let track = current else { return }
                navigate(to: ChartsVC(track: track), style: .fullScreen, transition: .flipHorizontal)
            case 1:
                nav(to: TrackListVC(delegate: tracksDelegate))
            case 2:
                nav(to: BoatTokensVC())
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
            switch indexPath.row {
            case 1: nav(to: BoatTokensVC())
            default: ()
            }
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
        delegate.onToken(token: nil)
        goBack()
    }
    
    func cellIdentifier(indexPath: IndexPath) -> String {
        switch state {
        case .content:
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
        case .empty:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0: return noTracksIdentifier
                default: return basicCellIdentifier
                }
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
        default: return basicCellIdentifier
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .content:
            switch section {
            case 0: return 1
            case 1: return 3
            case 2: return 1
            case 3: return 2
            default: return 0
            }
        case .empty:
            switch section {
            case 0: return 2
            case 1: return 1
            case 2: return 2
            default: return 0
            }
        default:
            return 0
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch state {
        case .content: return 4
        case .empty: return 3
        default: return 0
        }
    }
    
    func loadTracks() {
        let _ = Backend.shared.http.tracks().subscribe { (single) in
            self.onUiThread {
                switch single {
                case .success(let ts):
                    self.log.info("Got \(ts.count) tracks.")
                    self.onUiThread {
                        self.tableView.backgroundView = nil
                        self.onTracks(ts: ts.map { $0.track })
                    }
                case .error(let err):
                    self.state = .failed
                    self.tableView.backgroundView = self.feedbackView(text: "Failed to load profile.")
                    self.log.error("Unable to load tracks. \(err.describe)")
                }
            }
        }
    }
    
    func onTracks(ts: [TrackRef]) {
        state = ts.isEmpty ? .empty : .content
        summary = ts.first(where: { (track) -> Bool in
            track.trackName == current
        })
        tableView.reloadData()
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
