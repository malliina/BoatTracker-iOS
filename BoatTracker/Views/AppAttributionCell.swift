//
//  AttributionCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

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
