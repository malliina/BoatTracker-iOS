//
//  TrackSummaryCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class TrackSummaryCell: BoatCell {
    static let identifier = String(describing: TrackSummaryCell.self)
    
    let stats = TrackSummaryBox()
    
    override func configureView() {
        contentView.addSubview(stats)
        stats.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(12)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }
    
    func fill(track: TrackRef) {
        stats.fill(track: track)
    }
}
