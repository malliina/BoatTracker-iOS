import Foundation

public struct SpeedM: Comparable, DoubleCodable {
  static let zero = SpeedM(0)
  static let key = "speed"

  let mps: Double
  
  var value: Double { mps }
  var rounded: String { String(format: "%.2f", mps) }
  var roundedMps: String { String(format: "%.0f", mps) }

  //    public var description: String { formattedKnots }
//  var formattedKph: String { "\(roundedKph) m/s" }
//  var formattedKnots: String { "\(rounded) kn" }
//  func formatted(sourceType: SourceType) -> String {
//    switch sourceType {
//    case .mobi
//    }
//    isBoat ? formattedKnots : formattedKph
//    ""
//  }

  init(_ mps: Double) {
    self.mps = mps
  }

  public static func == (lhs: SpeedM, rhs: SpeedM) -> Bool {
    lhs.mps == rhs.mps
  }

  public static func < (lhs: SpeedM, rhs: SpeedM) -> Bool {
    lhs.mps < rhs.mps
  }
}

extension Double {
  public var metersPerSecond: SpeedM { SpeedM(self) }
}
