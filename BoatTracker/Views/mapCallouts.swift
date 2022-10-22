import Foundation
import MapboxMaps
import UIKit
import CoreLocation

class LimitAnnotation: CustomAnnotation {
    let limit: LimitArea
    let coord: CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D { coord }
    
    init(limit: LimitArea, coord: CLLocationCoordinate2D) {
        self.limit = limit
        self.coord = coord
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView {
        LimitCallout(annotation: self, lang: lang)
    }
}

class LimitInfoView: PopoverView {
    let log = LoggerFactory.shared.vc(TapListener.self)
    
    let limitsLabel = BoatLabel.smallSubtitle()
    let limitsValue = BoatLabel.smallTitle()
    
    let speedLabel = BoatLabel.smallSubtitle()
    let speedValue = BoatLabel.smallTitle()
    
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle()
    
    let fairwayLabel = BoatLabel.smallSubtitle()
    let fairwayValue = BoatLabel.smallTitle()
    
    let limit: LimitArea
    let lang: Lang
    
    init(limit: LimitArea, lang: Lang) {
        self.limit = limit
        self.lang = lang
        super.init(frame: .zero)
        setup(limit)
    }
    
    private func setup(_ limit: LimitArea) {
        let hasSpeed = limit.limit != nil
        let hasFairwayName = limit.fairwayName != nil
        let speedLabels = hasSpeed ? [speedLabel, speedValue] : []
        let fairwayLabels = hasFairwayName ? [ fairwayLabel, fairwayValue ] : []
        ([limitsLabel, limitsValue] + fairwayLabels + speedLabels).forEach { (label) in
            addSubview(label)
        }
        limitsLabel.text = lang.limits.limit
        limitsLabel.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview()
            make.leadingMargin.equalToSuperview().inset(inset)
            if hasFairwayName {
                make.width.equalTo(fairwayLabel)
            }
            if hasSpeed {
                make.width.equalTo(speedLabel)
            }
        }
        limitsValue.text = limit.types.map { $0.translate(lang: lang.limits.types) }.joined(separator: ", ")
        limitsValue.snp.makeConstraints { (make) in
            make.top.equalTo(limitsLabel)
            make.leading.equalTo(limitsLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
            if !hasSpeed && !hasFairwayName {
                make.bottomMargin.equalToSuperview()
            }
        }
        if hasSpeed {
            speedLabel.text = lang.limits.magnitude
            speedLabel.snp.makeConstraints { (make) in
                make.top.equalTo(limitsValue.snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(limitsLabel)
            }
            speedValue.text = limit.limit?.formattedKmh
            speedValue.snp.makeConstraints { (make) in
                make.top.equalTo(speedLabel)
                make.leading.equalTo(speedLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
                if !hasFairwayName {
                    make.bottomMargin.equalToSuperview()
                }
            }
        }
        if hasFairwayName {
            fairwayLabel.text = lang.limits.fairwayName
            fairwayLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasSpeed ? speedLabel : limitsLabel).snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(limitsLabel)
            }
            fairwayValue.text = limit.fairwayName?.value
            fairwayValue.snp.makeConstraints { (make) in
                make.top.equalTo(fairwayLabel)
                make.leading.equalTo(fairwayLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
                make.bottomMargin.equalToSuperview()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LimitCallout: PopoverView {
    let limit: LimitAnnotation
    let lang: Lang
    
    required init(annotation: LimitAnnotation, lang: Lang) {
        self.limit = annotation
        self.lang = lang
        super.init(frame: .zero)
        setup(limit: annotation.limit)
    }
    
    func setup(limit: LimitArea) {
        let table = LimitInfoView(limit: limit, lang: lang)
        let container = self
        container.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.bottomMargin.equalToSuperview().inset(inset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinimalMarkAnnotation: CustomAnnotation {
    let mark: MinimalMarineSymbol
    let coord: CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D { coord }
    
    init(mark: MinimalMarineSymbol, coord: CLLocationCoordinate2D) {
        self.mark = mark
        self.coord = coord
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView {
        MinimalMarkCallout(annotation: self, lang: lang, finnishWords: finnishSpecials)
    }
}

class MinimalMarkCallout: PopoverView {
    let log = LoggerFactory.shared.view(MinimalMarkCallout.self)
    let markAnnoation: MinimalMarkAnnotation
    let lang: Lang
    var markLang: MarkLang { lang.mark }
    let finnishWords: SpecialWords
    
    let nameValue = BoatLabel.centeredTitle()
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle()
    let ownerLabel = BoatLabel.smallSubtitle()
    let ownerValue = BoatLabel.smallTitle()
    
    var hasLocation: Bool { markAnnoation.mark.hasLocation }
 
    required init(annotation: MinimalMarkAnnotation, lang: Lang, finnishWords: SpecialWords) {
        self.markAnnoation = annotation
        self.lang = lang
        self.finnishWords = finnishWords
        super.init(frame: .zero)
        setup(mark: annotation.mark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(mark: MinimalMarineSymbol) {
        let container = self
        [ nameValue, locationLabel, locationValue, ownerLabel, ownerValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameValue.text = mark.name(lang: lang.language)?.value
        nameValue.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
        }
        
        if hasLocation {
            locationLabel.text = markLang.location
            locationLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameValue.snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(ownerLabel)
            }
            
            locationValue.text = mark.location(lang: lang.language)?.value
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = markLang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationValue : nameValue).snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
            if hasLocation {
                make.width.greaterThanOrEqualTo(locationLabel)
            }
            make.bottomMargin.equalToSuperview().inset(inset)
        }
        
        ownerValue.text = mark.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
            make.bottomMargin.equalToSuperview().inset(inset)
        }
    }
}

class MarkAnnotation: CustomAnnotation {
    let mark: MarineSymbol
    let coord: CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D { coord }
    
    init(mark: MarineSymbol, coord: CLLocationCoordinate2D) {
        self.mark = mark
        self.coord = coord
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView {
        MarkCallout(annotation: self, lang: lang, finnishWords: finnishSpecials)
    }
}

class PopoverView: UIView {
    let spacing = 8
    let largeSpacing = 16
    let inset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
}

class TrophyPopover: PopoverView {
    let info: CoordBody
    let lang: Lang
    
    let speedValue = BoatLabel.centeredTitle()
    let timeValue = BoatLabel.smallCenteredTitle()
    
    required init(info: CoordBody, lang: Lang) {
        self.info = info
        self.lang = lang
        super.init(frame: .zero)
        setup()
    }
    
    func setup() {
        [speedValue, timeValue].forEach(addSubview)
        speedValue.text = info.speed.formattedKnots
        speedValue.snp.makeConstraints { make in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
        }
        timeValue.text = info.time.dateTime
        timeValue.snp.makeConstraints { make in
            make.top.equalTo(speedValue.snp.bottom).offset(spacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
            make.bottomMargin.equalToSuperview().inset(inset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MarkCallout: PopoverView {
    let log = LoggerFactory.shared.view(MarkCallout.self)
    let markAnnoation: MarkAnnotation
    let lang: Lang
    var markLang: MarkLang { lang.mark }
    let finnishWords: SpecialWords
    
    let nameValue = BoatLabel.centeredTitle()
    let typeLabel = BoatLabel.smallSubtitle()
    let typeValue = BoatLabel.smallTitle()
    let constructionLabel = BoatLabel.smallSubtitle()
    let constructionValue = BoatLabel.smallTitle()
    let navigationLabel = BoatLabel.smallSubtitle()
    let navigationValue = BoatLabel.smallTitle()
    let locationLabel = BoatLabel.smallSubtitle()
    let locationValue = BoatLabel.smallTitle()
    let ownerLabel = BoatLabel.smallSubtitle()
    let ownerValue = BoatLabel.smallTitle()

    var hasConstruction: Bool { markAnnoation.mark.construction != nil }
    var hasLocation: Bool { markAnnoation.mark.hasLocation }
    var hasNav: Bool { markAnnoation.mark.navMark != .notApplicable }
  
    required init(annotation: MarkAnnotation, lang: Lang, finnishWords: SpecialWords) {
        self.markAnnoation = annotation
        self.lang = lang
        self.finnishWords = finnishWords
        super.init(frame: .zero)
        setup(mark: annotation.mark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(mark: MarineSymbol) {
        let container = self
        [ nameValue, typeLabel, typeValue, constructionLabel, constructionValue, navigationLabel, navigationValue, locationLabel, locationValue, ownerLabel, ownerValue ].forEach { label in
            container.addSubview(label)
        }
        
        nameValue.text = mark.name(lang: lang.language)?.value
        nameValue.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
        }
        
        typeLabel.text = markLang.aidType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameValue.snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
            make.width.greaterThanOrEqualTo(constructionLabel)
            make.width.greaterThanOrEqualTo(navigationLabel)
            make.width.greaterThanOrEqualTo(locationLabel)
            make.width.greaterThanOrEqualTo(ownerLabel)
        }
        
        typeValue.text = mark.aidType.translate(lang: markLang.aidTypes)
        typeValue.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel)
            make.leading.equalTo(typeLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
        }
        
        if let construction = mark.construction {
            constructionLabel.text = markLang.construction
            constructionLabel.snp.makeConstraints { (make) in
                make.top.equalTo(typeValue.snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            constructionValue.text = construction.translate(lang: markLang.structures)
            constructionValue.snp.makeConstraints { (make) in
                make.top.equalTo(constructionLabel)
                make.leading.equalTo(constructionLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
            }
        }
        
        if hasNav {
            navigationLabel.text = markLang.navigation
            navigationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasConstruction ? constructionValue : typeValue).snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            
            navigationValue.text = mark.navMark.translate(lang: markLang.navTypes)
            navigationValue.snp.makeConstraints { (make) in
                make.top.equalTo(navigationLabel)
                make.leading.equalTo(navigationLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
            }
        }
        
        if mark.hasLocation {
            locationLabel.text = markLang.location
            locationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
                make.width.equalTo(typeLabel)
            }
            
            locationValue.text = mark.location(lang: lang.language)?.value
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = markLang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationValue : hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
            make.width.equalTo(typeLabel)
            make.bottomMargin.equalToSuperview().inset(inset)
        }
        
        ownerValue.text = mark.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
            make.bottomMargin.equalToSuperview().inset(inset)
        }
    }
}

class FairwayAreaAnnotation: CustomAnnotation {
    let info: FairwayArea
    let limits: LimitArea?
    let coord: CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D { coord }
    
    required init(info: FairwayArea, limits: LimitArea?, coord: CLLocationCoordinate2D) {
        self.info = info
        self.limits = limits
        self.coord = coord
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView { FairwayAreaCallout(annotation: self, limits: limits, lang: lang) }
}

class FairwayAreaCallout: PopoverView {
    let log = LoggerFactory.shared.view(FairwayAreaAnnotation.self)
    
    let info: FairwayAreaAnnotation
    let limits: LimitArea?
    let lang: Lang
    var fairwayLang: FairwayLang { lang.fairway }
    
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
        super.init(frame: .zero)
        setup(annotation.info)
    }
    
    private func setup(_ info: FairwayArea) {
        let container = self
        let hasMark = info.markType != nil
        let markLabels = hasMark ? [ markLabel, markValue ] : []
        let limitsView = limits.map { LimitInfoView(limit: $0, lang: lang) }
        let hasLimits  = limitsView != nil
        if let limitsView = limitsView {
            container.addSubview(limitsView)
        }
        ([ownerLabel, typeLabel, typeValue, depthLabel, depthValue, harrowDepthLabel, harrowDepthValue] + markLabels).forEach { (label) in
            container.addSubview(label)
        }
        ownerLabel.text = info.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
        }
        typeLabel.text = fairwayLang.fairwayType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel.snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
            make.width.equalTo(depthLabel)
            make.width.equalTo(harrowDepthLabel)
            if let limitsView = limitsView {
                make.width.equalTo(limitsView.limitsLabel)
            }
            if hasMark {
                make.width.equalTo(markLabel)
            }
        }
        typeValue.text = info.fairwayType.translate(lang: fairwayLang.types)
        typeValue.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel)
            make.leading.equalTo(typeLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
        }
        depthLabel.text = fairwayLang.fairwayDepth
        depthLabel.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel.snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
        }
        depthValue.text = info.fairwayDepth.formatMeters
        depthValue.snp.makeConstraints { (make) in
            make.top.equalTo(depthLabel)
            make.leading.equalTo(depthLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
        }
        harrowDepthLabel.text = fairwayLang.harrowDepth
        harrowDepthLabel.snp.makeConstraints { (make) in
            make.top.equalTo(depthValue.snp.bottom).offset(spacing)
            make.leadingMargin.equalToSuperview().inset(inset)
        }
        harrowDepthValue.text = info.harrowDepth.formatMeters
        harrowDepthValue.snp.makeConstraints { (make) in
            make.top.equalTo(harrowDepthLabel)
            make.leading.equalTo(harrowDepthLabel.snp.trailing).offset(spacing)
            make.trailingMargin.equalToSuperview().inset(inset)
            if !hasMark && limits == nil {
                make.bottomMargin.equalToSuperview().inset(inset)
            }
        }
        if hasMark {
            markLabel.text = lang.mark.markType
            markLabel.snp.makeConstraints { (make) in
                make.top.equalTo(harrowDepthLabel.snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
            }
            markValue.text = info.markType?.translate(lang: lang.mark.types)
            markValue.snp.makeConstraints { (make) in
                make.top.equalTo(markLabel)
                make.leading.equalTo(markLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
                if limits == nil {
                    make.bottomMargin.equalToSuperview().inset(inset)
                }
            }
        }
        if let limitsView = limitsView {
            limitsView.snp.makeConstraints { (make) in
                make.top.equalTo((hasMark ? markValue : harrowDepthValue).snp.bottom).offset(spacing)
                make.leading.trailing.equalToSuperview()
                make.bottomMargin.equalToSuperview().inset(inset)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BoatAnnotation: CustomAnnotation {
    let info: BoatPoint
    var coordinate: CLLocationCoordinate2D { info.coord.coord }
    
    init(info: BoatPoint) {
        self.info = info
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView { TrackedBoatCallout(annotation: self, lang: lang) }
}

class TrackedBoatCallout: PopoverView {
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
        super.init(frame: .zero)
        setup(boat: annotation)
    }
    
    private func setup(boat: BoatAnnotation) {
        let info = boat.info
        let from = info.from
        let container = self
        container.addSubview(nameLabel)
        nameLabel.text = from.boatName.name
        nameLabel.snp.makeConstraints { (make) in
            make.topMargin.equalToSuperview().offset(largeSpacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
        }
        let hasTitle = from.trackTitle != nil
        if hasTitle {
            container.addSubview(trackTitleLabel)
            trackTitleLabel.text = lang.name
            trackTitleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameLabel.snp.bottom).offset(spacing)
                make.leadingMargin.equalToSuperview().inset(inset)
            }
            container.addSubview(trackTitleValue)
            trackTitleValue.text = from.trackTitle?.title
            trackTitleValue.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(trackTitleLabel)
                make.leading.equalTo(trackTitleLabel.snp.trailing).offset(spacing)
                make.trailingMargin.equalToSuperview().inset(inset)
            }
        }
        container.addSubview(dateTimeLabel)
        dateTimeLabel.text = info.coord.time.dateTime
        dateTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hasTitle ? trackTitleLabel.snp.bottom : nameLabel.snp.bottom).offset(spacing)
            make.leadingMargin.trailingMargin.equalToSuperview().inset(inset)
            make.bottomMargin.equalToSuperview().inset(inset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TrophyAnnotation: CustomAnnotation {
    let top: CoordBody
    var coordinate: CLLocationCoordinate2D { top.coord }
    
    init(top: CoordBody) {
        self.top = top
    }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView { TrophyPopover(info: top, lang: lang) }
}

struct TrophyPoint: Codable {
    let top: CoordBody
}

protocol CustomAnnotation {
    var coordinate: CLLocationCoordinate2D { get }
    
    func callout(lang: Lang, finnishSpecials: SpecialWords) -> PopoverView
}
