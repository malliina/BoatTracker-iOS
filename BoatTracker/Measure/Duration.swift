import Foundation

public struct Duration: Comparable, CustomStringConvertible, DoubleCodable, Hashable {
  static let k: Double = 1000.0
  static let zero = Duration(seconds: 0)

  let seconds: Double
  var value: Double { seconds }

  init(_ seconds: Double) {
    self.init(seconds: seconds)
  }

  init(seconds: Double) {
    self.seconds = seconds
  }

  public var description: String { return Formatting.shared.format(duration: self) }

  public static func == (lhs: Duration, rhs: Duration) -> Bool {
    lhs.seconds == rhs.seconds
  }

  public static func < (lhs: Duration, rhs: Duration) -> Bool {
    lhs.seconds < rhs.seconds
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}

extension Int {
  public var ms: Duration { Duration(seconds: Double(self) / Duration.k) }
  public var seconds: Duration { Duration(seconds: Double(self)) }
}

extension Double {
  public var ms: Duration { Duration(seconds: Double(self) / Duration.k) }
  public var seconds: Duration { Duration(seconds: Double(self)) }
}
