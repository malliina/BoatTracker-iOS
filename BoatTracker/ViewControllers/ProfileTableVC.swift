//
//  ProfileTableVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

extension ProfileTableVC: BoatSocketDelegate {
    func onCoords(event: CoordsData) {
        self.update(stats: event.from)
    }
}

enum ViewState {
    case empty
    case content
    case loading
    case failed
}

struct ProfileInfo: Identifiable {
    let tracksDelegate: TracksDelegate
    let user: UserToken
    let current: TrackName?
    let lang: Lang
    var id: String { user.email }
}

class ProfileVM: ObservableObject {
    let log = LoggerFactory.shared.vc(ProfileVM.self)
    
    @Published var state: ViewState = .loading
    @Published var tracks: [TrackRef] = []
    @Published var current: TrackName?
    var summary: TrackRef? {
        tracks.first { ref in
            ref.trackName == current
        }
    }
    let tracksDelegate: TracksDelegate?
    
    private var socket: BoatSocket { Backend.shared.socket }
    private var http: BoatHttpClient { Backend.shared.http }
    
    init(current: TrackName? = nil, tracksDelegate: TracksDelegate?) {
        self.current = current
        self.tracksDelegate = tracksDelegate
    }
        
    func versionText(lang: Lang) -> String? {
        if let bundleMeta = Bundle.main.infoDictionary,
           let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
           let buildId = bundleMeta["CFBundleVersion"] as? String {
            return "\(lang.appMeta.version) \(appVersion) \(lang.appMeta.build) \(buildId)"
        } else {
            return nil
        }
    }

    func loadTracks() async {
        await update(viewState: .loading)
        do {
            let ts = try await http.tracks()
            log.info("Got \(ts.count) tracks.")
            await update(ts: ts)
        } catch {
            log.error("Unable to load tracks. \(error.describe)")
            await update(viewState: .failed)
        }
    }
    
    @MainActor private func update(viewState: ViewState) {
        state = viewState
    }
    
    @MainActor private func update(ts: [TrackRef]) {
        tracks = ts
        state = ts.isEmpty ? .empty : .content
    }
    
    @MainActor private func update(err: Error) {
        state = .failed
    }
}

struct ProfileTableRepresentable: UIViewControllerRepresentable {
    let info: ProfileInfo
    
    func makeUIViewController(context: Context) -> ProfileTableVC {
        ProfileTableVC(tracksDelegate: info.tracksDelegate, current: info.current, user: info.user, lang: info.lang)
    }
    
    func updateUIViewController(_ uiViewController: ProfileTableVC, context: Context) {
        
    }
    
    typealias UIViewControllerType = ProfileTableVC
}

class ProfileTableVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(ProfileTableVC.self)
    
    let basicCellIdentifier = "BasicCell"
    let infoIdentifier = "InfoCell"
    let logoutIdentifier = "LogoutCell"
    let noTracksIdentifier = "NoTracksCell"
    let summaryRow = 0
    let summarySection = 0
    
//    let delegate: TokenDelegate
    let tracksDelegate: TracksDelegate
    let user: UserToken
    let current: TrackName?
    var lang: Lang
    
    var summary: TrackRef? = nil
    var state: ViewState = .loading
    var isInitial: Bool = false
    
    private var socket: BoatSocket {
        Backend.shared.socket
    }
    
    func update(stats: TrackRef) {
        onUiThread {
            if let current = self.current, stats.trackName == current {
                self.summary = stats
                if let cell = self.tableView?.cellForRow(at: IndexPath(row: self.summaryRow, section: self.summarySection)) as? TrackSummaryCell {
                    cell.fill(track: stats, lang: self.lang)
                } else {
                    self.log.debug("No cell. Live track update?")
                }
            }
        }
    }
    
    init(tracksDelegate: TracksDelegate, current: TrackName?, user: UserToken, lang: Lang) {
//        self.delegate = tokenDelegate
        self.tracksDelegate = tracksDelegate
        self.current = current
        self.user = user
        self.lang = lang
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: lang.map, style: .plain, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.title = lang.appName
        tableView?.register(TrackSummaryCell.self, forCellReuseIdentifier: TrackSummaryCell.identifier)
        [noTracksIdentifier, basicCellIdentifier, infoIdentifier, logoutIdentifier].forEach { (identifier) in
            tableView?.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        }
        loadTracks()
        socket.statsDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if settings.currentLanguage != lang.language, let newLang = settings.lang {
            self.lang = newLang
            navigationItem.title = newLang.appName
            navigationItem.leftBarButtonItem?.title = newLang.map
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier(indexPath: indexPath), for: indexPath)
        switch state {
        case .content:
            switch indexPath.section {
            case summarySection:
                cell.selectionStyle = .none
                if let summary = summary, let cell = cell as? TrackSummaryCell {
                    cell.fill(track: summary, lang: lang)
                }
            case 1:
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                if let label = cell.textLabel {
                    label.textColor = colors.textColor
                    label.textAlignment = .left
                    switch indexPath.row {
                    case 0: label.text = lang.track.graph
                    case 1: label.text = lang.track.trackHistory
                    case 2: label.text = lang.labels.statistics
                    case 3: label.text = lang.track.boats
                    default: ()
                    }
                }
            case 2:
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = lang.profile.language
            case 3:
                initAttributionsCell(cell: cell)
            case 4:
                initLogoutCells(cell: cell, indexPath: indexPath)
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
        if let label = cell.textLabel {
            label.text = lang.messages.noSavedTracks
            label.textColor = colors.secondaryText
            label.textAlignment = .center
        }
        cell.selectionStyle = .none
    }
    
    func initBoatsCell(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = lang.track.boats
    }
    
    func initAttributionsCell(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = lang.attributions.title
    }
    
    func initLogoutCells(cell: UITableViewCell, indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            if let label = cell.textLabel {
                label.text = "\(lang.profile.signedInAs) \(user.email)"
                label.textAlignment = .center
                label.textColor = .lightGray
            }
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case 1:
            if let label = cell.textLabel,
               let bundleMeta = Bundle.main.infoDictionary,
               let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
               let buildId = bundleMeta["CFBundleVersion"] as? String {
                label.text = "\(lang.appMeta.version) \(appVersion) \(lang.appMeta.build) \(buildId)"
                label.textAlignment = .center
                label.textColor = .lightGray
            }
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case 2:
            initLogout(cell: cell)
        default:
            ()
        }
    }
    
    func initLogout(cell: UITableViewCell) {
        if let label = cell.textLabel {
            label.text = lang.profile.logout
            label.textColor = .red
            label.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        40
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
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
                navigate(to: ChartsVC(track: track, lang: lang), style: .fullScreen, transition: .flipHorizontal)
            case 1:
                nav(to: TrackListVC(delegate: tracksDelegate, lang: lang))
            case 2:
                nav(to: StatsVC(lang: lang))
            case 3:
                openBoats()
            default: ()
            }
        case 2:
            switch indexPath.row {
            case 0: openLanguageSelection()
            default: openLanguageSelection()
            }
        case 3:
            openAttributions()
        case 4:
            switch indexPath.row {
            case 2: logout()
            default: ()
            }
        default: ()
        }
    }
    
    func didSelectLimited(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 1: openBoats()
            default: ()
            }
        case 1:
            openAttributions()
        case 2:
            switch indexPath.row {
            case 2: logout()
            default: ()
            }
        default: ()
        }
    }
    
    func openLanguageSelection() {
        nav(to: SelectLanguageVC(lang: lang.profile))
    }
    
    func openBoats() {
        nav(to: BoatTokensVC(lang: lang))
    }
    
    func openAttributions() {
        nav(to: AttributionsVC(info: lang.attributions))
    }
    
    func logout() {
        Task {
            await Auth.shared.signOut(from: self)
            goBack()
        }
    }
    
    func cellIdentifier(indexPath: IndexPath) -> String {
        switch state {
        case .content:
            switch indexPath.section {
            case summarySection:
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
        default:
            return basicCellIdentifier
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .content:
            switch section {
            case 0: return 1
            case 1: return 4
            case 2: return 1
            case 3: return 1
            case 4: return 3
            default: return 0
            }
        case .empty:
            switch section {
            case 0: return 2
            case 1: return 1
            case 2: return 1
            default: return 0
            }
        default:
            return 0
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch state {
        case .content: return 5
        case .empty: return 3
        default: return 0
        }
    }
    
    func loadTracks() {
        Task {
            do {
                let ts = try await Backend.shared.http.tracks()
                log.info("Got \(ts.count) tracks.")
                update(ts: ts)
            } catch {
                update(err: error)
            }
        }
    }
    
    @MainActor private func update(ts: [TrackRef]) {
        tableView.backgroundView = nil
        onTracks(ts: ts)
    }
    
    @MainActor private func update(err: Error) {
        state = .failed
        tableView.backgroundView = self.feedbackView(text: lang.messages.failedToLoadProfile)
        log.error("Unable to load tracks. \(err.describe)")
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
