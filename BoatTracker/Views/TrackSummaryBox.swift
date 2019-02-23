//
//  TrackSummaryBox.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class TrackSummaryBox: UIView {
    let date: StatBox
    let duration: StatBox
    let distance: StatBox
    let topSpeed: StatBox
    let avgSpeed: StatBox
    let avgWaterTemp: StatBox
    
    let spacingBig: CGFloat = 36
    let verticalSpacing: CGFloat = 36
    
    init() {
        date = StatBox()
        duration = StatBox()
        distance = StatBox()
        topSpeed = StatBox()
        avgSpeed = StatBox()
        avgWaterTemp = StatBox()
        super.init(frame: CGRect.zero)
        snap()
    }
    
    func snap() {
        isHidden = true
        addSubview(duration)
        duration.snp.makeConstraints { (make) in
            make.leadingMargin.topMargin.equalToSuperview()
        }
        addSubview(distance)
        distance.snp.makeConstraints { (make) in
            make.top.width.equalTo(duration)
            make.leading.equalTo(duration.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
        addSubview(topSpeed)
        topSpeed.snp.makeConstraints { (make) in
            make.top.equalTo(duration.snp.bottom).offset(verticalSpacing)
            make.leadingMargin.equalTo(duration)
        }
        addSubview(avgSpeed)
        avgSpeed.snp.makeConstraints { (make) in
            make.top.width.equalTo(topSpeed)
            make.leading.equalTo(topSpeed.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
        addSubview(avgWaterTemp)
        avgWaterTemp.snp.makeConstraints { (make) in
            make.top.equalTo(topSpeed.snp.bottom).offset(verticalSpacing)
            make.leadingMargin.equalTo(duration)
            make.width.equalTo(topSpeed)
            make.bottom.equalToSuperview()
        }
        addSubview(date)
        date.snp.makeConstraints { (make) in
            make.top.width.equalTo(avgWaterTemp)
            make.leading.equalTo(avgWaterTemp.snp.trailing).offset(spacingBig)
            make.trailingMargin.equalToSuperview()
        }
    }
    
    func fill(track: TrackRef, lang: Lang) {
        isHidden = false
        let trackLang = lang.track
        date.fill(label: trackLang.date, value: track.startDate(lang: lang.settings.formats))
        duration.fill(label: trackLang.duration, value: track.duration)
        distance.fill(label: trackLang.distance, value: track.distance)
        let notAvailable = lang.messages.notAvailable
        topSpeed.fill(label: trackLang.topSpeed, value: track.topSpeed?.description ?? notAvailable)
        avgSpeed.fill(label: trackLang.avgSpeed, value: track.avgSpeed?.description ?? notAvailable)
        avgWaterTemp.fill(label: trackLang.waterTemp, value: track.avgWaterTemp?.description ?? notAvailable)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
