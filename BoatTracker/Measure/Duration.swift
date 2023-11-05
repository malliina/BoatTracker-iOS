import Foundation

public struct Duration: Comparable, CustomStringConvertible, DoubleCodable {
  static let k: Double = 1000.0
  static let zero = Duration(seconds: 0)

  let seconds: Double
  var value: Double { return seconds }

  init(_ seconds: Double) {
    self.init(seconds: seconds)
  }

  init(seconds: Double) {
    self.seconds = seconds
  }

  public var description: String { return Formatting.shared.format(duration: self) }

  public static func == (lhs: Duration, rhs: Duration) -> Bool {
    return lhs.seconds == rhs.seconds
  }

  public static func < (lhs: Duration, rhs: Duration) -> Bool {
    return lhs.seconds < rhs.seconds
  }
}

extension Int {
  public var ms: Duration { return Duration(seconds: Double(self) / Duration.k) }
  public var seconds: Duration { return Duration(seconds: Double(self)) }
}

extension Double {
  public var ms: Duration { return Duration(seconds: Double(self) / Duration.k) }
  public var seconds: Duration { return Duration(seconds: Double(self)) }
}
