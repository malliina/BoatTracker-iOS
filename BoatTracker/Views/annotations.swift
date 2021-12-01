//
//  annotations.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import MapboxMaps

class FairwayAreaAnnotation: CustomAnnotation {
    let info: FairwayArea
    let limits: LimitArea?
    
    required init(info: FairwayArea, limits: LimitArea?, coord: CLLocationCoordinate2D) {
        self.info = info
        self.limits = limits
        super.init(coord: coord)
    }
    
    func callout(lang: Lang) -> FairwayAreaCallout { return FairwayAreaCallout(annotation: self, limits: limits, lang: lang) }
}

class FairwayAreaCallout: BoatCallout {
    let log = LoggerFactory.shared.view(FairwayAreaAnnotation.self)
    
    let info: FairwayAreaAnnotation
    let limits: LimitArea?
    let lang: Lang
    var fairwayLang: FairwayLang { return lang.fairway }
    
    let ownerLabel = BoatLabel.centeredTitle()
    let typeLabel = BoatLabel.smallSubtitle()
    let typeValue = BoatLabel.smallTitle()
    let depthLabel = BoatLabel.smallSubtitle()
    let depthValue = BoatLabel.smallTitle()
    let harrowDepthLabel = BoatLabel.smallSubtitle()
    let harrowDepthValue = BoatLabel.smallTitle()
    let markLabel = BoatLabel.smallSubtitle()
    let markValue = BoatLabel.smallTitle()
    
    required init(annotation: FairwayAreaAnnotation, limits: LimitArea?, lang: Lang) {
        self.info = annotation
        self.limits = limits
        self.lang = lang
        super.init()
        setup(annotation.info)
    }
    
    private func setup(_ info: FairwayArea) {
        let hasMark = info.markType != nil
        let markLabels = hasMark ? [ markLabel, markValue ] : []
        let limitsView = limits.map { LimitInfoView(limit: $0, lang: lang) }
        if let limitsView = limitsView {
            container.addSubview(limitsView)
        }
        ([ownerLabel, typeLabel, typeValue, depthLabel, depthValue, harrowDepthLabel, harrowDepthValue] + markLabels).forEach { (label) in
            container.addSubview(label)
        }
        ownerLabel.text = info.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        typeLabel.text = fairwayLang.fairwayType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(depthLabel)
            make.width.equalTo(harrowDepthLabel)
            if let limitsView = limitsView {
                make.width.equalTo(limitsView.fairwayLabel)
            }
            if hasMark {
                make.width.equalTo(markLabel)
            }
        }
        typeValue.text = info.fairwayType.translate(lang: fairwayLang.types)
        typeValue.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel)
            make.leading.equalTo(typeLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        depthLabel.text = fairwayLang.fairwayDepth
        depthLabel.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
        }
        depthValue.text = info.fairwayDepth.formatMeters
        depthValue.snp.makeConstraints { (make) in
            make.top.equalTo(depthLabel)
            make.leading.equalTo(depthLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        harrowDepthLabel.text = fairwayLang.harrowDepth
        harrowDepthLabel.snp.makeConstraints { (make) in
            make.top.equalTo(depthValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
        }
        harrowDepthValue.text = info.harrowDepth.formatMeters
        harrowDepthValue.snp.makeConstraints { (make) in
            make.top.equalTo(harrowDepthLabel)
            make.leading.equalTo(harrowDepthLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
            if !hasMark && limits == nil {
                make.bottom.equalToSuperview().inset(inset)
            }
        }
        if hasMark {
            markLabel.text = lang.mark.markType
            markLabel.snp.makeConstraints { (make) in
                make.top.equalTo(harrowDepthLabel.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
            }
            markValue.text = info.markType?.translate(lang: lang.mark.types)
            markValue.snp.makeConstraints { (make) in
                make.top.equalTo(markLabel)
                make.leading.equalTo(markLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
                if limits == nil {
                    make.bottom.equalToSuperview().inset(inset)
                }
            }
        }
        if let limitsView = limitsView {
            limitsView.snp.makeConstraints { (make) in
                make.top.equalTo((hasMark ? markValue : harrowDepthValue).snp.bottom).offset(spacing)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().inset(inset)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BoatAnnotation: CustomAnnotation {
    var info: BoatPoint
    
    init(info: BoatPoint) {
        self.info = info
        super.init(coord: info.coord.coord)
    }
}

class TrackedBoatCallout: BoatCallout {
    let log = LoggerFactory.shared.view(TrackedBoatCallout.self)
    
    let boat: BoatAnnotation
    let lang: Lang
    
    let nameLabel = BoatLabel.centeredTitle()
    let trackTitleLabel = BoatLabel.smallSubtitle()
    let trackTitleValue = BoatLabel.smallTitle()
    let dateTimeLabel = BoatLabel.smallCenteredTitle()
    
    required init(annotation: BoatAnnotation, lang: Lang) {
        self.boat = annotation
        self.lang = lang
        super.init()
        setup(boat: annotation)
    }
    
    private func setup(boat: BoatAnnotation) {
        let info = boat.info
        let from = info.from
        container.addSubview(nameLabel)
        nameLabel.text = from.boatName.name
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        let hasTitle = from.trackTitle != nil
        if hasTitle {
            container.addSubview(trackTitleLabel)
            trackTitleLabel.text = lang.name
            trackTitleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameLabel.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
            }
            container.addSubview(trackTitleValue)
            trackTitleValue.text = from.trackTitle?.title
            trackTitleValue.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(trackTitleLabel)
                make.leading.equalTo(trackTitleLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        container.addSubview(dateTimeLabel)
        dateTimeLabel.text = info.coord.time.dateTime
        dateTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hasTitle ? trackTitleLabel.snp.bottom : nameLabel.snp.bottom).offset(spacing)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(inset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// The iOS SDK uses the title and subtitle properties to render an inbuilt callout
class TrophyAnnotation: NSObject {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var top: CoordBody
    
    init(top: CoordBody) {
        self.top = top
        self.title = top.speed.description
        self.subtitle = top.time.dateTime
        self.coordinate = top.coord
    }
    
    func update(top: CoordBody) {
        self.top = top
        self.title = top.speed.description
        self.subtitle = top.time.dateTime
        self.coordinate = top.coord
    }
}

class RouteAnnotation: NSObject {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var isEnd: Bool
    
    init(at: CLLocationCoordinate2D, isEnd: Bool) {
        self.title = "t"
        self.subtitle = "s"
        self.coordinate = at
        self.isEnd = isEnd
    }
}

class CustomAnnotation: NSObject {
    // Insane hack: the MGLAnnotation object requires a title property, otherwise the callout is never shown.
    // Best source I could find is https://github.com/mapbox/react-native-mapbox-gl/issues/1278.
    var title: String? = ""
    var coordinate: CLLocationCoordinate2D
    
    init(coord: CLLocationCoordinate2D) {
        // The title value must also be defined
        self.title = ""
        self.coordinate = coord
    }
}
