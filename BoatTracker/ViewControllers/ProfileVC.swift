//
//  ProfileVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class ProfileVC: UIViewController {
    let log = LoggerFactory.shared.vc(ProfileVC.self)
    
    let feedbackLabel = BoatLabel.build(text: "")
    
    let statsView = UIView()
    let date = BoatLabel.build(text: "", alignment: .right)
    let duration = BoatLabel.build(text: "", alignment: .right)
    let distance = BoatLabel.build(text: "", alignment: .right)
    let topSpeed = BoatLabel.build(text: "", alignment: .right)
    let avgSpeed = BoatLabel.build(text: "", alignment: .right)
    let avgWaterTemp = BoatLabel.build(text: "", alignment: .right)
    
    let tracksButton = BoatButton.create(title: "Tracks", color: .blue)
    let logoutButton = BoatButton.create(title: "Logout")
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var delegate: TokenDelegate? = nil
    var tracksDelegate: TracksDelegate? = nil
    var current: TrackName? = nil
    
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
        
        view.backgroundColor = UIColor.white
        
        let spacing: CGFloat = 12
        let labelWidth: CGFloat = 160
        
        statsView.isHidden = true
        view.addSubview(statsView)
        statsView.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(24)
            make.leadingMargin.trailingMargin.equalToSuperview()
        }
        let dateLabel = label(text: "Date")
        statsView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.width.equalTo(labelWidth)
            make.top.leadingMargin.equalToSuperview()
        }
        statsView.addSubview(date)
        date.snp.makeConstraints { (make) in
            make.leading.equalTo(dateLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(dateLabel)
        }
        let durationLabel = label(text: "Duration")
        statsView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { (make) in
            make.top.equalTo(dateLabel.snp.bottom).offset(spacing)
            make.leadingMargin.width.equalTo(dateLabel)
        }
        statsView.addSubview(duration)
        duration.snp.makeConstraints { (make) in
            make.leading.equalTo(durationLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(durationLabel)
        }
        let distanceLabel = label(text: "Distance")
        statsView.addSubview(distanceLabel)
        distanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(durationLabel.snp.bottom).offset(spacing)
            make.leadingMargin.width.equalTo(dateLabel)
        }
        statsView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(distanceLabel)
        }
        let topSpeedLabel = label(text: "Top Speed")
        statsView.addSubview(topSpeedLabel)
        topSpeedLabel.snp.makeConstraints { (make) in
            make.top.equalTo(distanceLabel.snp.bottom).offset(spacing)
            make.leadingMargin.width.equalTo(dateLabel)
        }
        statsView.addSubview(topSpeed)
        topSpeed.snp.makeConstraints { (make) in
            make.leading.equalTo(topSpeedLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(topSpeedLabel)
        }
        let avgSpeedLabel = BoatLabel.build(text: "Avg Speed", alignment: .left)
        statsView.addSubview(avgSpeedLabel)
        avgSpeedLabel.snp.makeConstraints { (make) in
            make.top.equalTo(topSpeedLabel.snp.bottom).offset(spacing)
            make.leadingMargin.width.equalTo(dateLabel)
        }
        statsView.addSubview(avgSpeed)
        avgSpeed.snp.makeConstraints { (make) in
            make.leading.equalTo(avgSpeedLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(avgSpeedLabel)
            make.bottom.equalToSuperview()
        }
        let avgWaterLabel = BoatLabel.build(text: "Avg Water Temp", alignment: .left)
        statsView.addSubview(avgWaterLabel)
        avgWaterLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avgSpeedLabel.snp.bottom).offset(spacing)
            make.leadingMargin.width.equalTo(dateLabel)
            make.bottom.equalToSuperview()
        }
        statsView.addSubview(avgWaterTemp)
        avgWaterTemp.snp.makeConstraints { (make) in
            make.leading.equalTo(avgWaterLabel.snp.trailing).offset(spacing)
            make.centerY.equalTo(avgWaterLabel)
            make.bottom.equalToSuperview()
        }
        view.addSubview(tracksButton)
        tracksButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.topMargin.equalTo(statsView.snp.bottom).offset(36)
        }
        tracksButton.addTarget(self, action: #selector(tracksClicked(_:)), for: .touchUpInside)
        
        view.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.greaterThanOrEqualTo(tracksButton.snp.bottom).offset(spacing)
            make.bottom.equalToSuperview().inset(spacing)
        }
        logoutButton.addTarget(self, action: #selector(logoutClicked(_:)), for: .touchUpInside)
        
        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(logoutButton)
        }
        loadTracks()
    }
    
    private func label(text: String) -> UILabel {
        return BoatLabel.build(text: text, alignment: .left)
    }
    
    func loadTracks() {
        guard let current = current else {
            statsView.isHidden = true
            return
        }
        let _ = Backend.shared.http.tracks().subscribe { (single) in
            switch single {
            case .success(let ts):
                self.log.info("Got \(ts.count) tracks.")
                self.onUiThread {
                    let relevant = ts.first(where: { (summary) -> Bool in
                        summary.track.trackName == current
                    })
                    guard let track = relevant else { return }
                    self.update(summary: track)
                }
            case .error(let err):
                self.log.error("Unable to load tracks. \(err.describe)")
            }
        }
    }
    
    func update(summary: TrackSummary) {
        let track = summary.track
        date.text = track.startDate
        duration.text = track.duration.description
        distance.text = track.distance.description
        topSpeed.text = track.topSpeed?.description ?? "N/A"
        avgSpeed.text = track.avgSpeed?.description ?? "N/A"
        avgWaterTemp.text = track.avgWaterTemp?.description ?? "N/A"
        UIView.transition(with: statsView, duration: 0.6, options: .transitionCrossDissolve, animations: {
            self.statsView.isHidden = false
        }, completion: nil)
    }
    
    @objc func tracksClicked(_ sender: UIButton) {
        let dest = TrackListVC(delegate: tracksDelegate)
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
    @objc func logoutClicked(_ sender: UIButton) {
        GoogleAuth.shared.signOut()
        delegate?.onToken(token: nil)
        goBack()
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
    
}
