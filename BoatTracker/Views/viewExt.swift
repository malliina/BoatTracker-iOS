import Foundation
import UIKit
import SwiftUI

extension UIView {
    var colors: BoatColors { BoatColors.shared }
}

class Margins {
    static let shared = Margins()
    
    let small: CGFloat = 8
    let medium: CGFloat = 12
}

extension View {
    var margin: Margins { Margins.shared }
}

extension Optional {
    var toList: [Wrapped] {
        guard let s = self else { return [] }
        return [s]
    }
}
