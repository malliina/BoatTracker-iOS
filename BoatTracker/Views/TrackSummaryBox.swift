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
    let date = StatBox("Date")
    let duration = StatBox("Duration")
    let distance = StatBox("Distance")
    let topSpeed = StatBox("Top Speed")
    let avgSpeed = StatBox("Avg Speed")
    let avgWaterTemp = StatBox("Water Temp")
    
    let spacingBig: CGFloat = 36
    let verticalSpacing: CGFloat = 36
    
    init() {
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
    
    func fill(track: TrackRef) {
        isHidden = false
        date.value = track.startDate
        duration.value = track.duration.description
        distance.value = track.distance.description
        topSpeed.value = track.topSpeed?.description ?? "N/A"
        avgSpeed.value = track.avgSpeed?.description ?? "N/A"
        avgWaterTemp.value = track.avgWaterTemp?.description ?? "N/A"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
