import Foundation
import SwiftUI

struct TappedRepresentable: UIViewControllerRepresentable {
    let log = LoggerFactory.shared.view(TappedRepresentable.self)
    let lang: Lang
    let finnishWords: SpecialWords
    @Binding var tapped: Tapped?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let tapped = tapped, uiViewController.presentedViewController == nil {
            let swiftUiView = makeView(from: tapped)
                .padding()
                .onDisappear {
                    self.tapped = nil
                }
            let ctrl = UIHostingController(rootView: swiftUiView)
            ctrl.modalPresentationStyle = .popover
            if let popover = ctrl.popoverPresentationController {
                popover.delegate = context.coordinator
                popover.sourceView = tapped.source
                popover.sourceRect = CGRect(origin: tapped.point, size: .zero)
            } else {
//                log.info("No popover to configure")
            }
            let size = ctrl.view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            ctrl.preferredContentSize = CGSize(width: size.width, height: size.height)
            uiViewController.present(ctrl, animated: true)
        }
    }

    @ViewBuilder
    func makeView(from: Tapped) -> some View {
        let result = from.result
        switch result {
        case .trophy(let info, _):
            TrophyView(info: info)
        case .limit(let area, _):
            LimitView(limit: area, lang: lang)
        case .miniMark(let info, _):
            MinimalMarkView(info: info, lang: lang, finnishWords: finnishWords)
        case .mark(let info, _, _):
            MarkView(info: info, lang: lang, finnishWords: finnishWords)
        case .boat(let info):
            BoatView(info: info, lang: lang)
        case .vessel(let info):
            VesselView(vessel: info, lang: lang)
        case .area(let info, let limit):
            AreaView(info: info, limit: limit, lang: lang)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
        /// Essential to make the popup show as a popup and not as a near-full-page sheet on iOS
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            .none
        }
        
    }
    
    typealias UIViewControllerType = UIViewController
}
