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

    let dateTime = BoatLabel.build(alignment: .left, numberOfLines: 1)
    let title = BoatLabel.build(alignment: .left, textColor: .lightGray)
    let distance = StatBox(style: .small)
    let duration = StatBox(style: .small)
    let topSpeed = StatBox(style: .small)

    override func configureView() {
        contentView.addSubview(dateTime)
        dateTime.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateTime.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalTo(dateTime)
            make.leading.equalTo(dateTime.snp.trailing).offset(spacing)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        contentView.addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualTo(dateTime.snp.bottom).offset(spacing)
            make.top.greaterThanOrEqualTo(title.snp.bottom).offset(spacing)
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
    
    func fill(track: TrackRef, lang: Lang) {
        title.text = track.trackTitle?.title
        dateTime.text = track.times.start.date
        let trackLang = lang.track
        distance.fill(label: trackLang.distance, value: track.distance)
        duration.fill(label: trackLang.duration, value: track.duration)
        topSpeed.fill(label: trackLang.topSpeed, value: track.topSpeed?.description ?? lang.messages.notAvailable)
    }
}
