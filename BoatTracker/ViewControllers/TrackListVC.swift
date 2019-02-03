//
//  TrackListVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

protocol TracksDelegate {
    /// Called on the main thread.
    func onTrack(_ track: TrackName)
}

class TrackListVC: BaseTableVC, TokenDelegate {
    let log = LoggerFactory.shared.vc(TrackListVC.self)
    let cellKey = "TrackCell"
    
    var login: Bool = false
    
    private var tracks: [TrackRef] = []
    private var delegate: TracksDelegate? = nil
    
    init(delegate: TracksDelegate?, login: Bool = false) {
        self.delegate = delegate
        self.login = login
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Tracks"
        tableView?.register(TrackCell.self, forCellReuseIdentifier: cellKey)
//        tableView.rowHeight = TrackCell.rowHeight
        
        if login {
            // Dev time only
            GoogleAuth.shared.uiDelegate = self
            GoogleAuth.shared.signInSilently()
        } else {
            loadTracks()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath) as! TrackCell
        cell.fill(track: tracks[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = tracks[indexPath.row]
        self.delegate?.onTrack(selected.trackName)
        goBack()
    }
    
    func onToken(token: UserToken?) {
        Backend.shared.updateToken(new: token)
        loadTracks()
    }
    
    func loadTracks() {
        display(text: "Loading...")
        let _ = Backend.shared.http.tracks().subscribe { (single) in
            switch single {
            case .success(let ts):
                self.log.info("Got \(ts.count) tracks.")
                self.onUiThread {
                    if ts.isEmpty {
                        self.tableView.backgroundView = self.feedbackView(text: "Hello! You have no saved tracks. To save tracks, you'll need to connect the BoatTracker agent software to the GPS chartplotter in your boat.")
                    } else {
                        self.tableView.backgroundView = nil
                        self.tracks = ts
                    }
                    self.tableView.reloadData()
                }
            case .error(let err):
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
