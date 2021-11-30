//
//  BoatCallout.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import MapboxMaps
import UIKit

class BoatCallout: UIView {
    static let log = LoggerFactory.shared.view(BoatCallout.self)
    
    static let spacing = 8
    static let inset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
//    weak var delegate: MGLCalloutViewDelegate?
    
//    var representedObject: MGLAnnotation
    var leftAccessoryView: UIView = UIView()
    var rightAccessoryView: UIView = UIView()
    
    let container = UIView()
    
    let tipHeight: CGFloat = 10.0
    let tipWidth: CGFloat = 20.0
    let tipOffset: CGFloat = 20.0
    
    let spacing = BoatCallout.spacing
    let inset = BoatCallout.inset
    
    // Maintains placement state: we compute it and use it in presentCallout(...), then use it again in draw(...)
    private var horizontalPlacement: HorizontalPlacement = .center
    private var verticalPlacement: VerticalPlacement = .top
    private var annotationCenterRelativeToFrame: CGFloat = 0
    private var annotationCenterRelativeToScreen: CGFloat = 0
    
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
    
//    init(representedObject: MGLAnnotation) {
//        self.representedObject = representedObject
//        super.init(frame: .zero)
//        setupContainer()
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupContainer() {
        backgroundColor = .clear
        addSubview(container)
        container.backgroundColor = .white
        container.layer.cornerRadius = 4.0
        container.layer.borderColor = UIColor.white.cgColor
        // Without this an unsatisfied constraint warning was emitted
        container.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width).priority(.high)
        }
    }
    
    /// https://github.com/mapbox/ios-sdk-examples/blob/master/Examples/Swift/CustomCalloutView.swift
    /// rect is the tapped annotation
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
        // These two calls are used to give the container dimensions, which are used when presenting the callout for the tip + placement
        container.setNeedsLayout()
        container.layoutIfNeeded()
        
//        BoatCallout.log.info("Container height \(container.bounds.height) width \(container.bounds.width)")
        let frameHeight = container.bounds.height + tipHeight
        // Prefers a top placement, unless there's too little room
        // What's 8?
        verticalPlacement = rect.origin.y > frameHeight + 8 ? .top : .bottom
        if verticalPlacement == .bottom {
            // Shifts the container down, making room for the tip, which is outside the container but must be inside the frame.
            container.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(tipHeight)
            }
        }
        
        let containerWidth = container.bounds.width
        let frameOriginX = calloutOriginX(for: rect, calloutWidth: containerWidth)
        annotationCenterRelativeToScreen = annotationCenterRelativeToFrame - frameOriginX
        let frameOriginY = rect.origin.y + (verticalPlacement == .top ? -frameHeight : 0)
        frame = CGRect(x: frameOriginX, y: frameOriginY, width: containerWidth, height: frameHeight)
        
        if animated {
            alpha = 0
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.alpha = 1
            }
        }
    }
    
    func calloutOriginX(for annotation: CGRect, calloutWidth: CGFloat) -> CGFloat {
        let halfAnnotation = annotation.size.width / 2.0
        let originX = annotation.origin.x
        annotationCenterRelativeToFrame = originX + halfAnnotation
        horizontalPlacement = suggestPlacement(originX: annotationCenterRelativeToFrame)
        let minOriginX: CGFloat = 0
        let maxOriginX: CGFloat = max(0, UIScreen.main.bounds.width - calloutWidth)
        switch horizontalPlacement {
        case .left:
            // Callout goes to the left of the annotation, but not so much as to exceed the screen bounds
            return max(annotationCenterRelativeToFrame - calloutWidth + tipWidth, minOriginX)
        case .center:
            // Prefer center of annotation, but within screen bounds
            return min(max(annotationCenterRelativeToFrame - (calloutWidth / 2.0), minOriginX), maxOriginX)
        case .right:
            // Callout goes to the right of the annotation, but not so much right so as to exceed the screen bounds
            return min(max(annotationCenterRelativeToFrame - tipWidth, 0), maxOriginX)
        }
    }
    
    func suggestPlacement(originX x: CGFloat) -> HorizontalPlacement {
        let columnWidth = UIScreen.main.bounds.width / 3.0
        // | left | center | right |
        return x < columnWidth ? .right : x < (columnWidth * 2) ? .center : .left
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
        let tipCenter = annotationCenterRelativeToScreen
        let tipLeft = tipCenter - (tipWidth / 2.0)
        let heightWithoutTip = rect.size.height - tipHeight - 1
        
        let currentContext = UIGraphicsGetCurrentContext()!
        let tipPath = CGMutablePath()
        if verticalPlacement == .top {
            // The callout is on top of the annotation, therefore the tip goes below the callout
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
}
