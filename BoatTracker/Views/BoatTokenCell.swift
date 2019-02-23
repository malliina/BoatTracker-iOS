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
    
    let boatBox = StatBox(style: .large)
    let tokenBox = StatBox(style: .large)
    
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
    
    func fill(boat: BoatName, token: String, lang: SettingsLang) {
        boatBox.fill(label: lang.boat, value: boat)
        tokenBox.fill(label: lang.token, value: token)
    }
}
