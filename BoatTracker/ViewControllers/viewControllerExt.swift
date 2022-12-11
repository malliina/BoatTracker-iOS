import Foundation
import UIKit

extension UIViewController {
    var colors: BoatColors { return BoatColors.shared }
    
    func navigate(to: UIViewController, style: UIModalPresentationStyle = .formSheet, transition: UIModalTransitionStyle = .coverVertical) {
        let nav = UINavigationController(rootViewController: to)
        nav.modalPresentationStyle = style
        nav.modalTransitionStyle = transition
        nav.navigationBar.prefersLargeTitles = true
        present(nav, animated: true, completion: nil)
    }
    
    func nav(to: UIViewController) {
        navigationController?.pushViewController(to, animated: true)
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func onUiThread(_ f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: f)
    }
    
    func showIndicator(on: UIButton, indicator: UIActivityIndicatorView) {
        animated(view: on) {
            on.isHidden = true
            indicator.startAnimating()
        }
    }
    
    func hideIndicator(on: UIButton, indicator: UIActivityIndicatorView) {
        animated(view: on) {
            on.isHidden = false
            indicator.stopAnimating()
        }
    }
    
    func animated(view: UIView, changes: @escaping () -> Void) {
        UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: changes, completion: nil)
    }
}
