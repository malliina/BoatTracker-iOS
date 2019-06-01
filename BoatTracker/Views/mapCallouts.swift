//
//  MarkCallout.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

class LimitAnnotation: CustomAnnotation {
    let limit: LimitArea
    
    init(limit: LimitArea, coord: CLLocationCoordinate2D) {
        self.limit = limit
        super.init(coord: coord)
    }
    
    func callout(lang: Lang) -> LimitCallout {
        return LimitCallout(annotation: self, lang: lang)
    }
}

class LimitCallout: BoatCallout {
    let limit: LimitAnnotation
    let lang: Lang
    
    let limitsLabel = BoatLabel.smallSubtitle()
    let limitsValue = BoatLabel.smallTitle(numberOfLines: 0)
    
    let speedLabel = BoatLabel.smallSubtitle()
    let speedValue = BoatLabel.smallTitle()
    
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle()
    
    let fairwayLabel = BoatLabel.smallSubtitle()
    let fairwayValue = BoatLabel.smallTitle()
    
    required init(annotation: LimitAnnotation, lang: Lang) {
        self.limit = annotation
        self.lang = lang
        super.init(representedObject: annotation)
        setup(limit: annotation.limit)
    }
    
    func setup(limit: LimitArea) {
        let hasSpeed = limit.limit != nil
        let speedLabels = hasSpeed ? [speedLabel, speedValue] : []
        ([limitsLabel, limitsValue, fairwayLabel, fairwayValue] + speedLabels).forEach { (label) in
            container.addSubview(label)
        }
        limitsLabel.text = lang.limits.limit
        limitsLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.greaterThanOrEqualTo(limitsLabel)
            make.width.greaterThanOrEqualTo(fairwayLabel)
            if hasSpeed {
                make.width.greaterThanOrEqualTo(speedLabel)
            }
        }
        limitsValue.text = limit.types.map { $0.translate(lang: lang.limits.types) }.joined(separator: ", ")
        limitsValue.snp.makeConstraints { (make) in
            make.top.equalTo(limitsLabel)
            make.leading.equalTo(limitsLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        if hasSpeed {
            speedLabel.text = lang.limits.magnitude
            speedLabel.snp.makeConstraints { (make) in
                make.top.equalTo(limitsValue.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(limitsLabel)
            }
            speedValue.text = limit.limit?.formattedKmh
            speedValue.snp.makeConstraints { (make) in
                make.top.equalTo(speedLabel)
                make.leading.equalTo(speedLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        fairwayLabel.text = lang.limits.fairwayName
        fairwayLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasSpeed ? speedLabel : limitsLabel).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(limitsLabel)
        }
        fairwayValue.text = limit.fairwayName
        fairwayValue.snp.makeConstraints { (make) in
            make.top.equalTo(fairwayLabel)
            make.leading.equalTo(fairwayLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(inset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinimalMarkAnnotation: CustomAnnotation {
    let mark: MinimalMarineSymbol
    
    init(mark: MinimalMarineSymbol, coord: CLLocationCoordinate2D) {
        self.mark = mark
        super.init(coord: coord)
    }
}

class MinimalMarkCallout: BoatCallout {
    let log = LoggerFactory.shared.view(MinimalMarkCallout.self)
    let markAnnoation: MinimalMarkAnnotation
    let lang: Lang
    var markLang: MarkLang { return lang.mark }
    let finnishWords: SpecialWords
    
    let nameValue = BoatLabel.centeredTitle()
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle(numberOfLines: 0)
    let ownerLabel = BoatLabel.smallSubtitle()
    let ownerValue = BoatLabel.smallTitle()
    
    var hasLocation: Bool { return markAnnoation.mark.hasLocation }
 
    required init(annotation: MinimalMarkAnnotation, lang: Lang, finnishWords: SpecialWords) {
        self.markAnnoation = annotation
        self.lang = lang
        self.finnishWords = finnishWords
        super.init(representedObject: annotation)
        setup(mark: annotation.mark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(mark: MinimalMarineSymbol) {
        [ nameValue, locationLabel, locationValue, ownerLabel, ownerValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameValue.text = mark.name(lang: lang.language)?.value
        nameValue.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        if hasLocation {
            locationLabel.text = markLang.location
            locationLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameValue.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(ownerLabel)
            }
            
            locationValue.text = mark.location(lang: lang.language)?.value
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = markLang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationValue : nameValue).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            if hasLocation {
                make.width.greaterThanOrEqualTo(locationLabel)
            }
            make.bottom.equalToSuperview().inset(inset)
        }
        
        ownerValue.text = mark.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(inset)
        }
    }
}

class MarkAnnotation: CustomAnnotation {
    let mark: MarineSymbol
    
    init(mark: MarineSymbol, coord: CLLocationCoordinate2D) {
        self.mark = mark
        super.init(coord: coord)
    }
}

class MarkCallout: BoatCallout {
    let log = LoggerFactory.shared.view(MarkCallout.self)
    let markAnnoation: MarkAnnotation
    let lang: Lang
    var markLang: MarkLang { return lang.mark }
    let finnishWords: SpecialWords
    
    let nameValue = BoatLabel.centeredTitle()
    let typeLabel = BoatLabel.smallSubtitle()
    let typeValue = BoatLabel.smallTitle()
    let constructionLabel = BoatLabel.smallSubtitle()
    let constructionValue = BoatLabel.smallTitle()
    let navigationLabel = BoatLabel.smallSubtitle()
    let navigationValue = BoatLabel.smallTitle()
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle(numberOfLines: 0)
    let ownerLabel = BoatLabel.smallSubtitle()
    let ownerValue = BoatLabel.smallTitle()

    var hasConstruction: Bool { return markAnnoation.mark.construction != nil }
    var hasLocation: Bool { return markAnnoation.mark.hasLocation }
    var hasNav: Bool { return markAnnoation.mark.navMark != .notApplicable }
  
    required init(annotation: MarkAnnotation, lang: Lang, finnishWords: SpecialWords) {
        self.markAnnoation = annotation
        self.lang = lang
        self.finnishWords = finnishWords
        super.init(representedObject: annotation)
        setup(mark: annotation.mark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(mark: MarineSymbol) {
        [ nameValue, typeLabel, typeValue, constructionLabel, constructionValue, navigationLabel, navigationValue, locationLabel, locationValue, ownerLabel, ownerValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameValue.text = mark.name(lang: lang.language)?.value
        nameValue.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        typeLabel.text = markLang.aidType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.greaterThanOrEqualTo(constructionLabel)
            make.width.greaterThanOrEqualTo(navigationLabel)
            make.width.greaterThanOrEqualTo(locationLabel)
            make.width.greaterThanOrEqualTo(ownerLabel)
        }
        
        typeValue.text = mark.aidType.translate(lang: markLang.aidTypes)
        typeValue.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel)
            make.leading.equalTo(typeLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        if let construction = mark.construction {
            constructionLabel.text = markLang.construction
            constructionLabel.snp.makeConstraints { (make) in
                make.top.equalTo(typeValue.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            constructionValue.text = construction.translate(lang: markLang.structures)
            constructionValue.snp.makeConstraints { (make) in
                make.top.equalTo(constructionLabel)
                make.leading.equalTo(constructionLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        if hasNav {
            navigationLabel.text = markLang.navigation
            navigationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasConstruction ? constructionValue : typeValue).snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            
            navigationValue.text = mark.navMark.translate(lang: markLang.navTypes)
            navigationValue.snp.makeConstraints { (make) in
                make.top.equalTo(navigationLabel)
                make.leading.equalTo(navigationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        if mark.hasLocation {
            locationLabel.text = markLang.location
            locationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            
            locationValue.text = mark.location(lang: lang.language)?.value
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = markLang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationValue : hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(typeLabel)
            make.bottom.equalToSuperview().inset(inset)
        }
        
        ownerValue.text = mark.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(inset)
        }
    }
}
