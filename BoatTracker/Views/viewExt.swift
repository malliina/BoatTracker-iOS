import Foundation
import UIKit
import SwiftUI

extension UIView {
    var colors: BoatColors { BoatColors.shared }
}

class Margins {
    static let shared = Margins()
    
    let xxs: CGFloat = 4
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

struct ControllerRepresentable: UIViewControllerRepresentable {
    let log = LoggerFactory.shared.view(ControllerRepresentable.self)
    @Binding var vc: UIViewController?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        self.vc = vc
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    
    typealias UIViewControllerType = UIViewController
}
