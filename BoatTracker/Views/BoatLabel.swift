import Foundation
import UIKit

class BoatLabel {
    static func smallSubtitle(numberOfLines: Int = 1) -> UILabel {
        let label = smallTitle(textColor: .darkGray, numberOfLines: numberOfLines, fontSize: 14)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }
    
    static func smallTitle(textColor: UIColor = .black, numberOfLines: Int = 1, fontSize: CGFloat = 14) -> UILabel {
        return build(text: "", alignment: .left, numberOfLines: numberOfLines, fontSize: fontSize, textColor: textColor)
    }
    
    static func centeredTitle() -> UILabel {
        build(text: "", numberOfLines: 1, fontSize: 16)
    }
    
    static func smallCenteredTitle() -> UILabel {
        build(text: "", alignment: .center, numberOfLines: 1, fontSize: 12)
    }
    
    static func build(text: String = "", alignment: NSTextAlignment = .center, numberOfLines: Int = 0, fontSize: CGFloat = 17, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        label.font = label.font.withSize(fontSize)
        label.textColor = textColor
        return label
    }
}
