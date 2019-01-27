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

// https://stackoverflow.com/a/51906338
// https://docs.mapbox.com/ios/maps/examples/custom-callout/
class VesselCallout: UIView, MGLCalloutView {
    let log = LoggerFactory.shared.view(VesselCallout.self)
    var representedObject: MGLAnnotation
    var leftAccessoryView: UIView = UIView()
    var rightAccessoryView: UIView = UIView()
    
    weak var delegate: MGLCalloutViewDelegate?
    
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
    
    let container = UIView()
    let nameLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 16)
    let destinationLabel = BoatLabel.build(text: "Destination", alignment: .left, numberOfLines: 0, fontSize: 12, textColor: .darkGray)
    let destinationValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 12)
    let speedLabel = BoatLabel.build(text: "Speed", alignment: .left, numberOfLines: 0, fontSize: 12, textColor: .darkGray)
    let speedValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 12)
    let draftLabel = BoatLabel.build(text: "Draft", alignment: .left, numberOfLines: 0, fontSize: 12, textColor: .darkGray)
    let draftValue = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 12)
    let boatTimeLabel = BoatLabel.build(text: "", alignment: .left, numberOfLines: 0, fontSize: 12)

    let tipHeight: CGFloat = 10.0
    let tipWidth: CGFloat = 20.0
    // TODO un-hardcode these
    let containerWidth: CGFloat = 200
    let containerHeight: CGFloat = 120
    // Maintains placement state: we compute it and use it in presentCallout(...), then use it again in draw(...)
    private var placement: Placement = .center
    
    required init(annotation: VesselAnnotation) {
        self.representedObject = annotation
        super.init(frame: .zero)
        setup(vessel: annotation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(vessel: VesselAnnotation) {
        contentMode = .redraw
        let spacing = 8
        let inset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        backgroundColor = .clear
        addSubview(container)
        [ nameLabel, destinationLabel, destinationValue, speedLabel, speedValue, draftLabel, draftValue, boatTimeLabel ].forEach { label in
            container.addSubview(label)
        }
        
        container.backgroundColor = .white
        container.layer.cornerRadius = 4.0
        container.layer.borderColor = UIColor.white.cgColor
        // Without this an unsatisfied constraint warning was emitted (the hardcoded dimensions are for other reasons)
        container.snp.makeConstraints { (make) in
            make.width.equalTo(containerWidth)
            make.height.equalTo(containerHeight)
        }
        
        nameLabel.text = vessel.name
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview().inset(inset)
        }
        
        destinationLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(65)
        }
        
        destinationValue.text = vessel.destination
        destinationValue.snp.makeConstraints { (make) in
            make.top.equalTo(destinationLabel)
            make.leading.equalTo(destinationLabel.snp.trailing).offset(spacing)
            make.trailing.equalToSuperview().inset(inset)
        }
        
        speedLabel.snp.makeConstraints { (make) in
            make.top.equalTo(destinationLabel.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(inset)
            make.width.equalTo(destinationLabel)
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
            make.width.equalTo(destinationLabel)
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
    
    // https://github.com/mapbox/ios-sdk-examples/blob/master/Examples/Swift/CustomCalloutView.swift
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
//        container.setNeedsLayout()
//        container.layoutIfNeeded()
        let totalHeight = 16 + 16 + 8 + 4 + 4
//        container.layoutIfNeeded()
        log.info("Container: \(container.bounds.size) constrained \(constrainedRect) intrinsic \(container.intrinsicContentSize) with placement: \(suggestPlacement(originX: rect.origin.x)) Height could be \(totalHeight)")
        
        let frameHeight = containerHeight + tipHeight
        let frameOriginX = calloutOriginX(for: rect)
        let frameOriginY = rect.origin.y - frameHeight
        
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
        placement = suggestPlacement(originX: originX)
        switch placement {
        case .left: return basePosition - tipWidth
        case .center: return basePosition - (containerWidth / 2.0)
        case .right: return basePosition - containerWidth + tipWidth
        }
    }
    
    func suggestPlacement(originX x: CGFloat) -> Placement {
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
        log.info("Drawing tip with \(rect)")
        // Draw the pointed tip at the bottom.
        let fillColor: UIColor = .white

        let tipCenter = suggestTipCenter(rect)
        
        let tipLeft = tipCenter - (tipWidth / 2.0)
        let tipBottom = CGPoint(x: tipCenter, y: rect.origin.y + rect.size.height)
        let heightWithoutTip = rect.size.height - tipHeight - 1

        let currentContext = UIGraphicsGetCurrentContext()!

        let tipPath = CGMutablePath()
        tipPath.move(to: CGPoint(x: tipLeft, y: heightWithoutTip))
        tipPath.addLine(to: CGPoint(x: tipBottom.x, y: tipBottom.y))
        tipPath.addLine(to: CGPoint(x: tipLeft + tipWidth, y: heightWithoutTip))
        tipPath.closeSubpath()

        fillColor.setFill()
        currentContext.addPath(tipPath)
        currentContext.fillPath()
    }
    
    func suggestTipCenter(_ rect: CGRect) -> CGFloat {
        switch placement {
        case .left: return rect.origin.x + tipWidth
        case .center: return rect.origin.x + (rect.size.width / 2.0)
        case .right: return rect.origin.x + rect.size.width - tipWidth
        }
    }
}
// The trophy may be updated on the go while it's added to the map, therefore the model is mutable (and also to comply with MGLAnnotation)
class VesselAnnotation: NSObject, MGLAnnotation {
    // Insane hack: the MGLAnnotation object requires a title property, otherwise the callout is never shown.
    // Best source I could find is https://github.com/mapbox/react-native-mapbox-gl/issues/1278.
    var title: String?
    
    var name: String
    var destination: String?
    var speed: Speed
    var draft: Distance
    var boatTime: Date
    var coordinate: CLLocationCoordinate2D
    
    init(vessel: Vessel) {
        // The title value must also be defined
        self.title = ""
        
        self.name = vessel.name
        self.destination = vessel.destination
        self.speed = vessel.speed
        self.draft = vessel.draft
        self.boatTime = vessel.timestamp
        self.coordinate = vessel.coord
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
