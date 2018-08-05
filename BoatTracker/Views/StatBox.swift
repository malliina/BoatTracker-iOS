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
    let label: UILabel
    let valueText: UILabel
    
    var value: String {
        get { return valueText.text ?? "" }
        set { valueText.text = newValue }
    }
    
    convenience init(_ title: String, style: StatBoxStyle) {
        switch style {
        case .small:
            self.init(title, initialValue: "N/A", labelFontSize: 8, valueFontSize: 12, verticalSpace: 4)
        case .large:
            self.init(title, initialValue: "N/A", labelFontSize: 14, valueFontSize: 17, verticalSpace: 12)
        }
    }
    
    init(_ title: String, initialValue: String = "N/A", labelFontSize: CGFloat = 14, valueFontSize: CGFloat = 17, verticalSpace: CGFloat = 12) {
        label = BoatLabel.build(text: "", fontSize: labelFontSize, textColor: .darkGray)
        valueText = BoatLabel.build(text: "", fontSize: valueFontSize)
        super.init(frame: CGRect.zero)
        addSubview(label)
        addSubview(valueText)
        label.text = title
        valueText.text = initialValue
        snap(verticalSpace: verticalSpace)
    }
    
    func snap(verticalSpace: CGFloat) {
        label.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        valueText.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(verticalSpace)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func fill(value: String) {
        valueText.text = value
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
