//
//  TrophyCallout.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 27/01/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

// The annotation may be updated on the go while it's added to the map, therefore the model is mutable (and also to comply with MGLAnnotation)
class VesselAnnotation: CustomAnnotation {
    var name: String
    var destination: String?
    var speed: Speed
    var draft: Distance
    var boatTime: Date
    
    init(vessel: Vessel) {
        self.name = vessel.name
        self.destination = vessel.destination
        self.speed = vessel.speed
        self.draft = vessel.draft
        self.boatTime = vessel.timestamp
        super.init(coord: vessel.coord)
    }
    
    func update(with vessel: Vessel) {
        self.name = vessel.name
        self.destination = vessel.destination
        self.speed = vessel.speed
        self.draft = vessel.draft
        self.boatTime = vessel.timestamp
        self.coordinate = vessel.coord
    }
}

// https://stackoverflow.com/a/51906338
// https://docs.mapbox.com/ios/maps/examples/custom-callout/
class VesselCallout: BoatCallout {
    let log = LoggerFactory.shared.view(VesselCallout.self)
    let vessel: VesselAnnotation
    let lang: Lang
    
    let nameLabel = BoatLabel.centeredTitle()
    let destinationLabel = BoatLabel.smallSubtitle()
    let destinationValue = BoatLabel.smallTitle()
    let speedLabel = BoatLabel.smallSubtitle()
    let speedValue = BoatLabel.smallTitle()
    let draftLabel = BoatLabel.smallSubtitle()
    let draftValue = BoatLabel.smallTitle()
    let boatTimeValue = BoatLabel.build(text: "", alignment: .center, numberOfLines: 1, fontSize: 12)
    
    private var hasDestination: Bool { return vessel.destination != nil }
    
    required init(annotation: VesselAnnotation, lang: Lang) {
        self.vessel = annotation
        self.lang = lang
        super.init(representedObject: annotation)
        setup(vessel: annotation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(vessel: VesselAnnotation) {
        [ nameLabel, destinationLabel, destinationValue, speedLabel, speedValue, draftLabel, draftValue, boatTimeValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameLabel.text = vessel.name
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        if hasDestination {
            destinationLabel.text = lang.ais.destination
            destinationLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameLabel.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(speedLabel)
            }
            
            destinationValue.text = vessel.destination
            destinationValue.snp.makeConstraints { (make) in
                make.top.equalTo(destinationLabel)
                make.leading.equalTo(destinationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        speedLabel.text = lang.track.speed
        speedLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasDestination ? destinationLabel : nameLabel).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            if hasDestination {
                make.width.greaterThanOrEqualTo(destinationLabel)
            }
            make.width.greaterThanOrEqualTo(draftLabel)
        }
        
        speedValue.text = vessel.speed.description
        speedValue.snp.makeConstraints { (make) in
            make.top.equalTo(speedLabel)
            make.leading.equalTo(speedLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        draftLabel.text = lang.ais.draft
        draftLabel.snp.makeConstraints { (make) in
            make.top.equalTo(speedValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(speedLabel)
        }
        
        draftValue.text = vessel.draft.formatMeters
        draftValue.snp.makeConstraints { (make) in
            make.top.equalTo(draftLabel)
            make.leading.equalTo(draftLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        boatTimeValue.text = Formats.shared.dateTime(date: vessel.boatTime, lang: lang.settings.formats)
        boatTimeValue.snp.makeConstraints { (make) in
            make.top.equalTo(draftValue.snp.bottom).offset(spacing)
            make.leading.trailing.bottom.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(inset)
        }
    }
}
