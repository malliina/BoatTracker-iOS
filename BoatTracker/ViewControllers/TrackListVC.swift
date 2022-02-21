//
//  TrackListVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol TracksDelegate {
    /// Called on the main thread.
    func onTrack(_ track: TrackName)
}

class TrackListVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(TrackListVC.self)
    let cellKey = "TrackCell"
    
    var login: Bool = false
    
    private var tracks: [TrackRef] = []
    private var delegate: TracksDelegate? = nil
    
    let lang: Lang
    var settingsLang: SettingsLang { lang.settings }
    
    init(delegate: TracksDelegate?, login: Bool = false, lang: Lang) {
        self.delegate = delegate
        self.login = login
        self.lang = lang
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = lang.track.tracks
        tableView?.register(TrackCell.self, forCellReuseIdentifier: cellKey)
        loadTracks()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath) as! TrackCell
        cell.fill(track: tracks[indexPath.row], lang: lang)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = UIContextualAction(style: .normal, title: settingsLang.edit) { (action, view, bool) in
            self.showEditTitlePopup(tableView, at: indexPath, track: self.tracks[indexPath.row])
        }
        return UISwipeActionsConfiguration(actions: [item])
    }
    
    func showEditTitlePopup(_ tableView: UITableView, at indexPath: IndexPath, track: TrackRef) {
        let popup = UIAlertController(title: settingsLang.rename, message: settingsLang.newName, preferredStyle: .alert)
        popup.addTextField { textField in
            textField.text = track.trackTitle?.title
        }
        let okAction = UIAlertAction(title: settingsLang.rename, style: .default) { (a) in
            guard let textField = (popup.textFields ?? []).headOption(),
                let newName = textField.text, !newName.isEmpty else { return }
            let _ = self.backend.http.changeTrackTitle(name: track.trackName, title: TrackTitle(newName)).observe(on: MainScheduler.instance).subscribe { (single) in
                switch single {
                case .success(let updatedTrack):
                    self.tracks[indexPath.row] = updatedTrack.track
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                case .failure(let err):
                    self.log.error("Unable to rename. \(err.describe)")
                }
            }
        }
        popup.addAction(okAction)
        popup.addAction(UIAlertAction(title: settingsLang.cancel, style: .cancel, handler: nil))
        present(popup, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = tracks[indexPath.row]
        self.delegate?.onTrack(selected.trackName)
        goBack()
    }
    
    func loadTracks() {
        display(text: lang.messages.loading)
        let _ = backend.http.tracks().subscribe { (single) in
            switch single {
            case .success(let ts):
                self.log.info("Got \(ts.count) tracks.")
                self.onUiThread {
                    if ts.isEmpty {
                        self.tableView.backgroundView = self.feedbackView(text: self.lang.settings.noTracksHelp)
                    } else {
                        self.tableView.backgroundView = nil
                        self.tracks = ts
                    }
                    self.tableView.reloadData()
                }
            case .failure(let err):
                self.onError(err)
            }
        }
    }
    
    func onError(_ err: Error) {
        log.error(err.describe)
        display(text: err.describe)
    }
    
    func display(text: String) {
        onUiThread {
            let feedbackLabel = BoatLabel.build(text: text, alignment: .center, numberOfLines: 0)
            feedbackLabel.textColor = BoatColors.shared.feedback
            self.tableView.backgroundView = feedbackLabel
            self.tracks = []
            self.tableView.reloadData()
        }
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}

extension Error {
    var describe: String {
        guard let appError = self as? AppError else { return "An error occurred. \(self)" }
        return appError.describe
    }
}
