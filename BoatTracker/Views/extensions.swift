import Foundation
import SwiftUI
import MapboxMaps

extension Map {
  func onLayersTapGesture(_ layerIds: [String], perform action: @escaping MapLayerGestureHandler) -> Self {
    layerIds.foldLeft(self) { m, layerId in
      m.onLayerTapGesture(layerId, perform: action)
    }
  }
}

extension GeometryProxy {
  var realSize: CGSize {
    return CGSize(width: size.width + safeAreaInsets.leading + safeAreaInsets.trailing, height: size.height + safeAreaInsets.top + safeAreaInsets.bottom)
  }
}

extension MapboxMap {
  @MainActor
  func queryFeatures(at: CGPoint, layerIds: [String]) async throws -> [QueriedRenderedFeature] {
    try await withCheckedThrowingContinuation { cont in
      queryRenderedFeatures(
        with: at, options: RenderedQueryOptions(layerIds: layerIds, filter: nil)
      ) { result in
        switch result {
        case .success(let features):
          cont.resume(returning: features)
        case .failure(let error):
//          self.log.warn("Failed to query rendered features. \(error)")
          cont.resume(throwing: error)
        }
      }
    }
  }
  
  struct CameraInfo {
    let bearing, pitch: CGFloat
  }
  
  func queryVisibleFeatureProps<T: Decodable>(_ point: CGPoint, layers: [String], t: T.Type) async
    -> T?
  {
    do {
      let features = try await queryFeatures(at: point, layerIds: layers)
      return try features.first.flatMap { feature in
        let props = feature.queriedFeature.feature.properties ?? [:]
        return try props.parse(t)
      }
    } catch {
//      log.warn("Failed to parse props from layers \(layers.joined(separator: ", ")). \(error)")
      return nil
    }
  }
}

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
