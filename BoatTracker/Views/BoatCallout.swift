//
//  BoatCallout.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox
import UIKit

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
