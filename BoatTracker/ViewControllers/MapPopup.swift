import Foundation
import SwiftUI
import SnapKit

/// To display a popup, don't use .popover or .sheet in SwiftUI, but set this as a .background to your View
/// The rationale should be defined, since this is the only SnapKit usage in the app.
struct PopupRepresentable: UIViewControllerRepresentable {
    let popup: MapPopup?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let popup = popup, uiViewController.presentedViewController == nil {
            uiViewController.present(popup, animated: true)
        }
    }

    typealias UIViewControllerType = UIViewController
}

class MapPopup: UIViewController, Identifiable {
    let child: UIView
    let id: String

    init(child: UIView, id: String) {
        self.child = child
        self.id = id
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(child)
        view.backgroundColor = BoatColors.shared.backgroundColor
        child.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        preferredContentSize = CGSize(width: size.width, height: size.height)
    }
}
