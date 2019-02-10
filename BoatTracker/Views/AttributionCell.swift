//
//  AttributionCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class AttributionCell: BoatCell {
    let title = BoatLabel.build(text: "")
    let subText = BoatLabel.build(text: "", numberOfLines: 0)
    let link = BoatButton.nav(title: "", fontSize: 14)
    
    var attribution: Attribution? = nil
    
    static let rowHeight: CGFloat = 120
    
    override func configureView() {
        contentView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        contentView.addSubview(subText)
        subText.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(spacing)
        }
        contentView.addSubview(link)
        link.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(subText.snp.bottom).offset(spacing)
            make.bottom.equalTo(contentView.snp.bottom).inset(spacing)
        }
        link.addTarget(self, action: #selector(linkClicked(_:)), for: .touchUpInside)
    }
    
    func fill(with data: Attribution) {
        attribution = data
        title.text = data.title
        subText.text = data.text
        link.setTitle(data.link.text, for: .normal)
    }
    
    @objc func linkClicked(_ sender: UIButton) {
        guard let url = attribution?.link.url else { return }
        open(url: url)
    }
    
    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

class LinksAttributionCell: BoatCell {
    let title = BoatLabel.build(text: "")
    let link1 = BoatButton.nav(title: "", fontSize: 14)
    let link2 = BoatButton.nav(title: "", fontSize: 14)
    
    static let rowHeight: CGFloat = 120
    
    var data: LinksAttribution? = nil
    
    override func configureView() {
        contentView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        contentView.addSubview(link1)
        link1.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(spacing)
        }
        contentView.addSubview(link2)
        link2.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(link1.snp.bottom).offset(spacing)
            make.bottom.equalTo(contentView.snp.bottom).inset(spacing)
        }
        link1.addTarget(self, action: #selector(link1Clicked(_:)), for: .touchUpInside)
        link2.addTarget(self, action: #selector(link2Clicked(_:)), for: .touchUpInside)
    }
    
    func fill(with data: LinksAttribution) {
        self.data = data
        title.text = data.title
        link1.setTitle(data.link1.text, for: .normal)
        link2.setTitle(data.link2.text, for: .normal)
    }
    
    @objc func link1Clicked(_ sender: UIButton) {
        guard let url = data?.link1.url else { return }
        open(url: url)
    }
    
    @objc func link2Clicked(_ sender: UIButton) {
        guard let url = data?.link2.url else { return }
        open(url: url)
    }
    
    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
