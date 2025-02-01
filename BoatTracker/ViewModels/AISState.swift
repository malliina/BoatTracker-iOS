import Foundation
import MapboxMaps
import UIKit

class AISState {
  static let shared = AISState()
  private let maxTrailLength = 200

  private var vesselHistory: [Mmsi: [Vessel]] = [:]

  var history: [Mmsi: [Vessel]] { vesselHistory }

  func info(_ mmsi: Mmsi) -> Vessel? {
    vesselHistory[mmsi]?.first
  }

  func update(vessels: [Vessel]) {
    vessels.forEach { v in
      vesselHistory.updateValue(
        ([v] + (vesselHistory[v.mmsi] ?? [])).take(maxTrailLength),
        forKey: v.mmsi)
    }
  }

  func clear() {
    vesselHistory.removeAll()
  }
}
