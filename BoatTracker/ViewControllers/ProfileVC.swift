//
//  ProfileVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

extension ProfileVC: TokenDelegate {
    func onToken(token: AccessToken?) {
        Backend.shared.updateToken(new: token)
        loadTracks()
    }
}

class ProfileVC: UIViewController {
    let log = LoggerFactory.shared.vc(ProfileVC.self)
    
    let feedbackLabel = BoatLabel.build(text: "")
    
    let statsView = UIView()

    let date = StatBox("Date")
    let duration = StatBox("Duration")
    let distance = StatBox("Distance")
    let topSpeed = StatBox("Top Speed")
    let avgSpeed = StatBox("Avg Speed")
    let avgWaterTemp = StatBox("Water Temp")
    
    let tracksButton = BoatButton.create(title: "More Tracks", color: .blue)
    let logoutButton = BoatButton.create(title: "Logout")
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var delegate: TokenDelegate? = nil
    var tracksDelegate: TracksDelegate? = nil
    var current: TrackName? = nil
    var login: Bool = true
    
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
        
        let container = UIScrollView()
        view.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        //let content = UIView()
        //container.addSubview(content)
//        content.snp.makeConstraints { (make) in
//            make.left.right.equalTo(view)
//            make.top.equalToSuperview()
//        }

        view.backgroundColor = UIColor.white
        
        let spacingBig: CGFloat = 36
        let verticalSpacing: CGFloat = 36

        statsView.isHidden = true
        container.addSubview(statsView)
        statsView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(verticalSpacing)
            make.leadingMargin.trailingMargin.equalTo(view)
        }
        statsView.addSubview(duration)
        duration.snp.makeConstraints { (make) in
            make.leadingMargin.topMargin.equalToSuperview()
        }
        statsView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.width.equalTo(duration)
            make.leading.equalTo(duration.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
        statsView.addSubview(topSpeed)
        topSpeed.snp.makeConstraints { (make) in
            make.top.equalTo(duration.snp.bottom).offset(verticalSpacing)
            make.leadingMargin.equalTo(duration)
        }
        statsView.addSubview(avgSpeed)
        avgSpeed.snp.makeConstraints { (make) in
            make.top.width.equalTo(topSpeed)
            make.leadingMargin.equalTo(topSpeed.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
        statsView.addSubview(avgWaterTemp)
        avgWaterTemp.snp.makeConstraints { (make) in
            make.top.equalTo(topSpeed.snp.bottom).offset(verticalSpacing)
            make.leadingMargin.equalTo(duration)
            make.width.equalTo(topSpeed)
            make.bottom.equalToSuperview()
        }
        statsView.addSubview(date)
        date.snp.makeConstraints { (make) in
            make.top.width.equalTo(avgWaterTemp)
            make.leading.equalTo(avgWaterTemp.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
        container.addSubview(tracksButton)
        tracksButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalTo(view)
            make.topMargin.equalTo(statsView.snp.bottom).offset(48)
        }
        tracksButton.addTarget(self, action: #selector(tracksClicked(_:)), for: .touchUpInside)
        
        container.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalTo(view)
            make.top.greaterThanOrEqualTo(tracksButton.snp.bottom).offset(verticalSpacing)
            make.bottom.equalTo(container).inset(spacingBig)
            //make.bottom.lessThanOrEqualTo(view).priority(.low)
        }
        logoutButton.addTarget(self, action: #selector(logoutClicked(_:)), for: .touchUpInside)
        
        container.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { (make) in
            make.centerX.centerY.equalTo(logoutButton)
        }
        if login {
            // Dev time only
            GoogleAuth.shared.uiDelegate = self
            GoogleAuth.shared.signInSilently()
        } else {
            loadTracks()
        }
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
        date.value = track.startDate
        duration.value = track.duration.description
        distance.value = track.distance.description
        topSpeed.value = track.topSpeed?.description ?? "N/A"
        avgSpeed.value = track.avgSpeed?.description ?? "N/A"
        avgWaterTemp.value = track.avgWaterTemp?.description ?? "N/A"
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
