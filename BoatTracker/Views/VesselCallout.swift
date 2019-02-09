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

class MarkCallout: BoatCallout {
    let log = LoggerFactory.shared.view(MarkCallout.self)
    let markAnnoation: MarkAnnotation
    let lang: MarkLang
    
    let nameValue = BoatLabel.build(text: "", alignment: .center, numberOfLines: 1, fontSize: 16)
    let typeLabel = BoatLabel.build(text: "Type", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let typeValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let constructionLabel = BoatLabel.build(text: "Construction", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let constructionValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let navigationLabel = BoatLabel.build(text: "Navigation", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let navigationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let locationLabel = BoatLabel.build(text: "Location", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let locationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let ownerLabel = BoatLabel.build(text: "Owner", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let ownerValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    
    // TODO un-hardcode these
    var hasConstruction: Bool { return markAnnoation.mark.construction != nil }
    var hasLocation: Bool { return markAnnoation.mark.hasLocation }
    var hasNav: Bool { return markAnnoation.mark.navMark != .notApplicable }
    override var rows: Int { return 3 + (hasConstruction ? 1 : 0) + (hasLocation ? 1 : 0) + (hasNav ? 1 : 0) }
    override var containerWidth: CGFloat { return 240 }
    
    required init(annotation: MarkAnnotation, lang: MarkLang) {
        self.markAnnoation = annotation
        self.lang = lang
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
        
        nameValue.text = mark.nameFi ?? mark.nameSe ?? ""
        nameValue.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        typeLabel.text = lang.aidType
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
        }
        
        typeValue.text = "Type \(mark.aidType)"
        typeValue.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel)
            make.leading.equalTo(typeLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        if let construction = mark.construction {
            constructionLabel.text = lang.construction
            constructionLabel.snp.makeConstraints { (make) in
                make.top.equalTo(typeValue.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(labelWidth)
            }
            constructionValue.text = "Constr \(construction)"
            constructionValue.snp.makeConstraints { (make) in
                make.top.equalTo(constructionLabel)
                make.leading.equalTo(constructionLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        if hasNav {
            navigationLabel.text = lang.navigation
            navigationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasConstruction ? constructionValue : typeValue).snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(labelWidth)
            }
            
            navigationValue.text = "Nav \(mark.navMark)"
            navigationValue.snp.makeConstraints { (make) in
                make.top.equalTo(navigationLabel)
                make.leading.equalTo(navigationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        if let location = mark.locationFi ?? mark.locationSe {
            locationLabel.text = lang.location
            locationLabel.snp.makeConstraints { (make) in
                make.top.equalTo((hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(labelWidth)
            }
            
            locationValue.text = location
            locationValue.snp.makeConstraints { (make) in
                make.top.equalTo(locationLabel)
                make.leading.equalTo(locationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        ownerLabel.text = lang.owner
        ownerLabel.snp.makeConstraints { (make) in
            make.top.equalTo((hasLocation ? locationLabel : hasNav ? navigationLabel : hasConstruction ? constructionLabel : typeLabel).snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
        }
        
        ownerValue.text = mark.owner
        ownerValue.snp.makeConstraints { (make) in
            make.top.equalTo(ownerLabel)
            make.leading.equalTo(ownerLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
    }
}

// https://stackoverflow.com/a/51906338
// https://docs.mapbox.com/ios/maps/examples/custom-callout/
class VesselCallout: BoatCallout {
    let log = LoggerFactory.shared.view(VesselCallout.self)
    let vessel: VesselAnnotation
    
    let nameLabel = BoatLabel.build(text: "", alignment: .center, numberOfLines: 1, fontSize: 16)
    let destinationLabel = BoatLabel.build(text: "Destination", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let destinationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let speedLabel = BoatLabel.build(text: "Speed", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let speedValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let draftLabel = BoatLabel.build(text: "Draft", alignment: .left, numberOfLines: 1, fontSize: 12, textColor: .darkGray)
    let draftValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 1, fontSize: 12)
    let boatTimeLabel = BoatLabel.build(text: "", alignment: .center, numberOfLines: 1, fontSize: 12)

    // TODO un-hardcode these
    var hasDestination: Bool { return vessel.destination != nil }
    override var containerWidth: CGFloat { return hasDestination ? 200 : 160 }
    override var rows: Int { return hasDestination ? 5 : 4 }
    
    required init(annotation: VesselAnnotation) {
        self.vessel = annotation
        super.init(representedObject: annotation)
        setup(vessel: annotation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(vessel: VesselAnnotation) {
        let labelWidth = 65
        
        [ nameLabel, destinationLabel, destinationValue, speedLabel, speedValue, draftLabel, draftValue, boatTimeLabel ].forEach { label in
            container.addSubview(label)
        }
        
        nameLabel.text = vessel.name
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        if hasDestination {
            destinationLabel.snp.makeConstraints { (make) in
                make.top.equalTo(nameLabel.snp.bottom).offset(spacing)
                make.leading.equalToSuperview().inset(inset)
                make.width.equalTo(labelWidth)
            }
            
            destinationValue.text = vessel.destination
            destinationValue.snp.makeConstraints { (make) in
                make.top.equalTo(destinationLabel)
                make.leading.equalTo(destinationLabel.snp.trailing).offset(spacing)
                make.trailing.equalToSuperview().inset(inset)
            }
        }
        
        speedLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hasDestination ? destinationLabel.snp.bottom : nameLabel.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
        }
        
        speedValue.text = vessel.speed.description
        speedValue.snp.makeConstraints { (make) in
            make.top.equalTo(speedLabel)
            make.leading.equalTo(speedLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        draftLabel.snp.makeConstraints { (make) in
            make.top.equalTo(speedValue.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(labelWidth)
        }
        
        draftValue.text = vessel.draft.formatMeters
        draftValue.snp.makeConstraints { (make) in
            make.top.equalTo(draftLabel)
            make.leading.equalTo(draftLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        boatTimeLabel.text = Formats.shared.timestamped(date: vessel.boatTime)
        boatTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(draftValue.snp.bottom).offset(spacing)
            make.leading.trailing.bottom.equalToSuperview().inset(inset)
        }
    }
}

class BoatCallout: UIView, MGLCalloutView {
    weak var delegate: MGLCalloutViewDelegate?
    
    var representedObject: MGLAnnotation
    var leftAccessoryView: UIView = UIView()
    var rightAccessoryView: UIView = UIView()
    
    let container = UIView()
    
    let tipHeight: CGFloat = 10.0
    let tipWidth: CGFloat = 20.0
    let spacing = 8
    let inset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    // Maintains placement state: we compute it and use it in presentCallout(...), then use it again in draw(...)
    private var horizontalPlacement: HorizontalPlacement = .center
    private var verticalPlacement: VerticalPlacement = .top
    
    // Override these
    var containerWidth: CGFloat { return 0 }
    var containerHeight: CGFloat { return CGFloat(80 + (rows - 3) * 24) }
    var rows: Int { return 0 }
    
    // https://github.com/mapbox/mapbox-gl-native/issues/9228
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    
    init(representedObject: MGLAnnotation) {
        self.representedObject = representedObject
        super.init(frame: .zero)
        setupContainer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupContainer() {
        backgroundColor = .clear
        addSubview(container)
        container.backgroundColor = .white
        container.layer.cornerRadius = 4.0
        container.layer.borderColor = UIColor.white.cgColor
        // Without this an unsatisfied constraint warning was emitted (the hardcoded dimensions are for other reasons)
        container.snp.makeConstraints { (make) in
            make.width.equalTo(containerWidth)
            make.height.equalTo(containerHeight)
        }
    }
    
    // https://github.com/mapbox/ios-sdk-examples/blob/master/Examples/Swift/CustomCalloutView.swift
    // rect is the tapped annotation
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
        let frameHeight = containerHeight + tipHeight
        // Prefers a top placement, unless there's too little room
        verticalPlacement = rect.origin.y > frameHeight + 8 ? .top : .bottom
        if verticalPlacement == .bottom {
            // Shifts the container down, making room for the tip, which is outside the container but must be inside the frame.
            container.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(tipHeight)
            }
        }
        
        let frameOriginX = calloutOriginX(for: rect)
        let frameOriginY = rect.origin.y + (verticalPlacement == .top ? -frameHeight : 0)
        frame = CGRect(x: frameOriginX, y: frameOriginY, width: containerWidth, height: frameHeight)
        
        if animated {
            alpha = 0
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.alpha = 1
            }
        }
    }
    
    func calloutOriginX(for rect: CGRect) -> CGFloat {
        let halfAnnotation = rect.size.width / 2.0
        let originX = rect.origin.x
        let basePosition = originX + halfAnnotation
        horizontalPlacement = suggestPlacement(originX: originX)
        switch horizontalPlacement {
        case .left: return basePosition - tipWidth
        case .center: return basePosition - (containerWidth / 2.0)
        case .right: return basePosition - containerWidth + tipWidth
        }
    }
    
    func suggestPlacement(originX x: CGFloat) -> HorizontalPlacement {
        let columnWidth = UIScreen.main.bounds.width / 3.0
        // | left | center | right |
        return x < columnWidth ? .left : x < (columnWidth * 2) ? .center : .right
    }
    
    func dismissCallout(animated: Bool) {
        if (superview != nil) {
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 0
                    }, completion: { [weak self] _ in
                        self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        // Draws the pointed tip of the callout.
        // Placement is top/bottom and left/center/right.
        let fillColor: UIColor = .white
        let tipCenter = suggestTipCenter(rect)
        let tipLeft = tipCenter - (tipWidth / 2.0)
        let heightWithoutTip = rect.size.height - tipHeight - 1
        
        let currentContext = UIGraphicsGetCurrentContext()!
        let tipPath = CGMutablePath()
        if verticalPlacement == .top {
            // The popup is on top of the annotation, therefore the tip goes below the popup
            let bottomLeft = CGPoint(x: tipLeft, y: heightWithoutTip)
            let bottomCenter = CGPoint(x: tipCenter, y: rect.origin.y + rect.size.height)
            let bottomRight = CGPoint(x: tipLeft + tipWidth, y: heightWithoutTip)
            tipPath.move(to: bottomLeft)
            tipPath.addLine(to: bottomCenter)
            tipPath.addLine(to: bottomRight)
        } else {
            let topCenter = CGPoint(x: tipCenter, y: rect.origin.y)
            let topLeft = CGPoint(x: tipLeft, y: topCenter.y + tipHeight + 1)
            let topRight = CGPoint(x: tipLeft + tipWidth, y: topCenter.y + tipHeight + 1)
            tipPath.move(to: topLeft)
            tipPath.addLine(to: topCenter)
            tipPath.addLine(to: topRight)
        }
        
        tipPath.closeSubpath()
        
        fillColor.setFill()
        currentContext.addPath(tipPath)
        currentContext.fillPath()
    }
    
    func suggestTipCenter(_ rect: CGRect) -> CGFloat {
        switch horizontalPlacement {
        case .left: return rect.origin.x + tipWidth
        case .center: return rect.origin.x + (rect.size.width / 2.0)
        case .right: return rect.origin.x + rect.size.width - tipWidth
        }
    }
}
