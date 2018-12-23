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
    static let identifier = String(describing: TrackCell.self)

    let dateTime = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let distance = StatBox("Distance", style: .small)
    let duration = StatBox("Duration", style: .small)
    let topSpeed = StatBox("Top", style: .small)

    override func configureView() {
        contentView.addSubview(dateTime)
        dateTime.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        contentView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.equalTo(dateTime.snp.bottom).offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
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
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.bottom.equalToSuperview().inset(spacing)
        }
    }
    
    func fill(track: TrackRef) {
        dateTime.text = track.startDate
        distance.value = track.distance.description
        duration.value = track.duration.description
        topSpeed.value = track.topSpeed?.description ?? "N/A"
    }
}
