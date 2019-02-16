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
    
    var attribution: AppAttribution? = nil
    
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
    
    func fill(with data: AppAttribution) {
        attribution = data
        title.text = data.title
        subText.text = data.text
        guard let firstLink = data.links.first else { return }
        link.setTitle(firstLink.text, for: .normal)
    }
    
    @objc func linkClicked(_ sender: UIButton) {
        guard let url = attribution?.links.first?.url else { return }
        open(url: url)
    }
    
    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

class LinksAttributionCell: BoatCell {
    var title = BoatLabel.build(text: "")
    var link1 = BoatButton.nav(title: "", fontSize: 14)
    var link2 = BoatButton.nav(title: "", fontSize: 14)
    
    static let rowHeight: CGFloat = 120
    
    var data: AppAttribution? = nil
    
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
    
    func fill(with data: AppAttribution) {
        self.data = data
        title.text = data.title
        link1.setTitle(data.links[0].text, for: .normal)
        link2.setTitle(data.links[1].text, for: .normal)
    }
    
    @objc func link1Clicked(_ sender: UIButton) {
        guard let url = data?.links[0].url else { return }
        open(url: url)
    }
    
    @objc func link2Clicked(_ sender: UIButton) {
        guard let url = data?.links[1].url else { return }
        open(url: url)
    }
    
    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

class AppAttributionCell: BoatCell {
    var title: UILabel? = nil
    var subTitle: UILabel? = nil
    var links: [UIButton] = []
    
    var data: AppAttribution? = nil
    
    override func configureView() {
    }
    
    func fill(with data: AppAttribution) {
        self.data = data
        if title == nil {
            let titleLabel = BoatLabel.build(text: data.title)
            title = titleLabel
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(spacing)
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.trailing.equalTo(contentView.snp.trailingMargin)
            }
        }
        if let text = data.text, let title = title {
            if subTitle == nil {
                let subLabel = BoatLabel.build(text: text)
                subTitle = subLabel
                contentView.addSubview(subLabel)
                subLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(title)
                    make.top.equalTo(title.snp.bottom).offset(spacing)
                }
            }
        }
        data.links.enumerated().forEach { (offset, link) in
            let exists = links.indices.contains(offset)
            guard let viewAbove = offset == 0 ? subTitle ?? title : links[offset-1] else { return }
            if !exists {
                let btn = BoatButton.nav(title: link.text, fontSize: 14)
                contentView.addSubview(btn)
                links.append(btn)
                btn.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(viewAbove)
                    make.top.equalTo(viewAbove.snp.bottom).offset(spacing)
                    let isLast = offset == data.links.count - 1
                    if isLast {
                        make.bottom.equalTo(contentView.snp.bottom).inset(spacing)
                    }
                }
                btn.addTarget(self, action: #selector(linkClicked(_:)), for: .touchUpInside)
            }
        }
    }
    
    @objc func linkClicked(_ sender: UIButton) {
        guard let idx = links.firstIndex(of: sender) else { return }
        guard let url = data?.links[idx].url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
