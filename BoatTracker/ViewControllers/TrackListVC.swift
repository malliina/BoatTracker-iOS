//
//  TrackListVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class TrackListVC: BaseTableVC, TokenDelegate {
    let log = LoggerFactory.shared.vc(TrackListVC.self)
    let cellKey = "TrackCell"
    
    private var tracks: [TrackSummary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Tracks"
        tableView?.register(TrackCell.self, forCellReuseIdentifier: cellKey)
        tableView.rowHeight = TrackStatsVC.rowHeight
        
        GoogleAuth.shared.uiDelegate = self
        GoogleAuth.shared.signInSilently()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath) as! TrackCell
        cell.fill(summary: tracks[indexPath.row])
        return cell
    }
    
    func onToken(token: AccessToken?) {
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
                    self.tableView.backgroundView = nil
                    self.tracks = ts
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
}

extension Error {
    var describe: String {
        guard let appError = self as? AppError else { return "An error occurred. \(self)" }
        return appError.describe
    }
}
