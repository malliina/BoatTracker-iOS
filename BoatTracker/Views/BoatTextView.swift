import Foundation
import UIKit

class BoatTextView: UITextView {
    init(text: String?, font: UIFont) {
        super.init(frame: CGRect.zero, textContainer: nil)
        self.text = text
        self.font = font
        isScrollEnabled = false
        isEditable = false
        dataDetectorTypes = .link
        textColor = colors.secondaryText
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
