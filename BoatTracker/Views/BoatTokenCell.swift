//
//  BoatTokenCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 21/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class BoatTokenCell: BoatCell {
    static let identifier = String(describing: BoatTokenCell.self)
    
    let boatBox = StatBox("Boat", style: .large)
    let tokenBox = StatBox("Token", style: .large)
    
    override func configureView() {
        contentView.addSubview(boatBox)
        boatBox.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.bottom.equalToSuperview().inset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(tokenBox)
        tokenBox.snp.makeConstraints { (make) in
            make.top.bottom.width.equalTo(boatBox)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.leading.equalTo(boatBox.snp.trailing).offset(spacing)
        }
    }
    
    func fill(boat: BoatName, token: String) {
        boatBox.fill(value: boat.name)
        tokenBox.fill(value: token)
    }
}
