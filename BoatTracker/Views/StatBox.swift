//
//  StatBox.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 04/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

enum StatBoxStyle {
    case small
    case large
}

class StatBox: UIView {
    let labelText: UILabel
    let valueText: UILabel
    
    var value: String {
        get { return valueText.text ?? "" }
        set { valueText.text = newValue }
    }
    
    convenience init(_ title: String = "", style: StatBoxStyle) {
        switch style {
        case .small:
            self.init(title, labelFontSize: 12, valueFontSize: 15, verticalSpace: 6)
        case .large:
            self.init(title, labelFontSize: 14, valueFontSize: 17, verticalSpace: 12)
        }
    }
    
    init(_ title: String = "", labelFontSize: CGFloat = 14, valueFontSize: CGFloat = 17, verticalSpace: CGFloat = 12) {
        labelText = BoatLabel.build(text: title, fontSize: labelFontSize, textColor: BoatColors.shared.secondaryText)
        valueText = BoatLabel.build(fontSize: valueFontSize)
        super.init(frame: CGRect.zero)
        addSubview(labelText)
        addSubview(valueText)
        snap(verticalSpace: verticalSpace)
    }
    
    func snap(verticalSpace: CGFloat) {
        labelText.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        valueText.snp.makeConstraints { (make) in
            make.top.equalTo(labelText.snp.bottom).offset(verticalSpace)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func fill(label: String, value: CustomStringConvertible) {
        labelText.text = label
        valueText.text = value.description
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
