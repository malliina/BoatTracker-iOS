//
//  PeriodStatCell.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/08/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation

class PeriodStatCell: BoatCell {
    static let identifier = String(describing: PeriodStatCell.self)
    
    let dateTime = BoatLabel.build(alignment: .left, numberOfLines: 1)
    let title = BoatLabel.build(alignment: .left, textColor: .lightGray)
    let distance = StatBox(style: .small)
    let duration = StatBox(style: .small)
    let days = StatBox(style: .small)
    
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
            make.bottom.equalToSuperview().inset(spacing)
        }
        contentView.addSubview(days)
        days.snp.makeConstraints { (make) in
            make.top.equalTo(duration)
            make.leading.equalTo(duration.snp.trailing).offset(spacing)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.width.equalTo(duration)
            make.bottom.equalToSuperview().inset(spacing)
        }
    }
    
    func fill(year: YearlyStats, lang: Lang) {
        dateTime.text = "\(year.year)"
        title.text = ""
        distance.fill(label: lang.track.distance, value: year.distance)
        duration.fill(label: lang.track.duration, value: year.duration)
        days.fill(label: lang.track.days, value: year.days)
    }
    
    func fill(month: MonthlyStats, lang: Lang) {
        dateTime.text = month.label
        title.text = ""
        distance.fill(label: lang.track.distance, value: month.distance)
        duration.fill(label: lang.track.duration, value: month.duration)
        days.fill(label: lang.track.days, value: month.days)
    }
}
