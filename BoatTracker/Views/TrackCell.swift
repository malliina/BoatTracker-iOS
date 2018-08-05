//
//  TrackCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 21/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class TrackCell: BoatCell {
    static let rowHeight: CGFloat = 80
    
    let trackName = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let dateTime = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let distance = StatBox("Distance", initialValue: "N/A", labelFontSize: 8, valueFontSize: 12, verticalSpace: 4)
    let duration = StatBox("Duration", initialValue: "N/A", labelFontSize: 8, valueFontSize: 12, verticalSpace: 4)
    let topSpeed = StatBox("Top", initialValue: "N/A", labelFontSize: 8, valueFontSize: 12, verticalSpace: 4)
    let avgWaterTemp = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 14)
    
    let spacing = 12
    let fieldWidth = 80
    
    override func configureView() {
        contentView.addSubview(dateTime)
        dateTime.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(trackName)
        trackName.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.leading.equalTo(dateTime.snp.trailing).offset(spacing)
            make.width.equalTo(dateTime)
        }
        contentView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.equalTo(dateTime.snp.bottom).offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.width.equalTo(fieldWidth)
        }
        contentView.addSubview(duration)
        duration.snp.makeConstraints { (make) in
            make.top.equalTo(distance)
            make.leading.equalTo(distance.snp.trailing).offset(spacing)
            make.width.equalTo(distance)
        }
        contentView.addSubview(topSpeed)
        topSpeed.snp.makeConstraints { (make) in
            make.top.equalTo(distance)
            make.leading.equalTo(duration.snp.trailing).offset(spacing)
            make.width.equalTo(distance)
            make.trailing.equalToSuperview()
        }
    }
    
    func fill(summary: TrackSummary) {
        let track = summary.track
        dateTime.text = track.startDate
        //trackName.text = track.trackName.description
        distance.value = track.distance.description
        duration.value = track.duration.description
        topSpeed.value = track.topSpeed?.description ?? "N/A"
        avgWaterTemp.text = track.avgWaterTemp?.description ?? "N/A"
    }
}
