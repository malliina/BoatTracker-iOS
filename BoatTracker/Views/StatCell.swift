//
//  StatCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class StatCell: BoatCell {
    static let identifier = String(describing: StatCell.self)
    
    let titleLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    let statLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0)
    
    override func configureView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
//            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(statLabel)
        statLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.width.equalTo(100)
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
        }
    }
    
    func fill(kv: LabeledValue) {
        titleLabel.text = kv.label
        statLabel.text = kv.value
    }
}
