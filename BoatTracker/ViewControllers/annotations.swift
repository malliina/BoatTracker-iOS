//
//  annotations.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

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
        super.init(representedObject: annotation)
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

class TrophyAnnotation: NSObject, MGLAnnotation {
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

class RouteAnnotation: NSObject, MGLAnnotation {
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

class CustomAnnotation: NSObject, MGLAnnotation {
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
