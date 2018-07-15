//
//  TrackStatsVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

struct LabeledValue {
    let label: String
    let value: String
}

extension String {
    func withValue(_ value: CustomStringConvertible) -> LabeledValue {
        return LabeledValue(label: self, value: value.description)
    }
}

class TrackStatsVC: UITableViewController {
    static let rowHeight: CGFloat = 60
    static func testTrack() -> TrackRef {
        return TrackRef(trackName: TrackName(name: "Tname"), boatName: BoatName(name: "Bname"), username: Username(name: "Uname"), topSpeed: 1.knots, avgSpeed: 1.knots, distance: 10.kilometers, duration: 10.seconds, avgWaterTemp: 1.celsius)
    }
    
    let cellKey = "StatCell"
    
    let track: TrackRef
    let data: [LabeledValue]
    
    init(track: TrackRef) {
        self.track = track
        self.data = [
            "Distance".withValue(track.distance),
            "Duration".withValue(track.duration),
            "Top speed".withValue(track.topSpeed),
            "Avg speed".withValue(track.avgSpeed),
            "Water temp".withValue(track.avgWaterTemp)
        ]
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Stats"
        tableView?.register(StatCell.self, forCellReuseIdentifier: cellKey)
        tableView.rowHeight = TrackStatsVC.rowHeight
        // Removes separators when there are no more rows
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath) as! StatCell
        let kv = data[indexPath.row]
        cell.titleLabel.text = kv.label
        cell.statLabel.text = kv.value
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
}
