//
//  MarkCallout.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

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
    
    let nameValue = BoatLabel.build(text: "", alignment: .center, numberOfLines: 1, fontSize: 16)
    let typeLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let typeValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let constructionLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let constructionValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let navigationLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let navigationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let locationLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let locationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let ownerLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let ownerValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    
    // TODO un-hardcode these
    var hasConstruction: Bool { return markAnnoation.mark.construction != nil }
    var hasLocation: Bool { return markAnnoation.mark.hasLocation }
    var hasNav: Bool { return markAnnoation.mark.navMark != .notApplicable }
    override var rows: Int { return 3 + (hasConstruction ? 1 : 0) + (hasLocation ? 1 : 0) + (hasNav ? 1 : 0) }
    override var containerWidth: CGFloat { return 240 }
    
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
        let labelWidth = 75
        
        [ nameValue, typeLabel, typeValue, constructionLabel, constructionValue, navigationLabel, navigationValue, locationLabel, locationValue, ownerLabel, ownerValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameValue.text = mark.name(lang: lang.language)
        nameValue.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        typeLabel.text = markLang.aidType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
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
                make.width.equalTo(labelWidth)
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
                make.width.equalTo(labelWidth)
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
                make.width.equalTo(labelWidth)
            }
            
            locationValue.text = mark.location(lang: lang.language)
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = markLang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationLabel : hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
        }
        
        ownerValue.text = mark.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
    }
}
