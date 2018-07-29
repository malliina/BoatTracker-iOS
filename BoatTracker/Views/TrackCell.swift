//
//  TrackCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 21/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class TrackCell: BoatCell {
    let trackName = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let distance = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let duration = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let topSpeed = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let avgWaterTemp = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    
    let spacing = 12
    let fieldWidth = 80
    
    override func configureView() {
        contentView.addSubview(trackName)
        trackName.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        
        contentView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.equalTo(trackName.snp.bottom).offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.width.equalTo(fieldWidth)
        }
        contentView.addSubview(duration)
        duration.snp.makeConstraints { (make) in
            make.top.equalTo(distance)
            make.leading.equalTo(distance.snp.trailing).offset(spacing)
            make.width.equalTo(fieldWidth)
        }
        contentView.addSubview(topSpeed)
        topSpeed.snp.makeConstraints { (make) in
            make.top.equalTo(distance)
            make.leading.equalTo(duration.snp.trailing).offset(spacing)
            make.width.equalTo(fieldWidth)
        }
        contentView.addSubview(avgWaterTemp)
        avgWaterTemp.snp.makeConstraints { (make) in
            make.top.equalTo(distance)
            make.leading.equalTo(topSpeed.snp.trailing).offset(spacing)
            make.width.equalTo(fieldWidth)
        }
    }
    
    func fill(summary: TrackSummary) {
        let track = summary.track
        trackName.text = track.trackName.description
        distance.text = track.distance.description
        duration.text = track.duration.description
        topSpeed.text = track.topSpeed?.description ?? "N/A"
        avgWaterTemp.text = track.avgWaterTemp?.description ?? "N/A"
    }
}
