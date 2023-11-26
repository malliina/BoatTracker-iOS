import Foundation
import SwiftUI

extension ObservableObject {
  var backend: Backend { Backend.shared }
  var http: BoatHttpClient { backend.http }
  var prefs: BoatPrefs { BoatPrefs.shared }
  var settings: UserSettings { UserSettings.shared }
}

extension View {
  var color: BoatColor { BoatColor.shared }
}

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

extension PreviewProvider {
  static var lang: Lang { BoatPreviews.conf.languages.english }
}
