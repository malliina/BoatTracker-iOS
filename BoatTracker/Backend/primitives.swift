import Foundation

struct BoatName: Equatable, Hashable, CustomStringConvertible, StringCodable {
  static let key = "boatName"
  let name: String
  var description: String { name }

  init(_ name: String) {
    self.name = name
  }

  static func == (lhs: BoatName, rhs: BoatName) -> Bool { lhs.name == rhs.name }
}

struct TrackName: Hashable, CustomStringConvertible, StringCodable {
  static let key = "trackName"
  let name: String
  var description: String { name }

  init(_ name: String) {
    self.name = name
  }

  static func == (lhs: TrackName, rhs: TrackName) -> Bool {
    lhs.name == rhs.name
  }
}

struct TrackTitle: Hashable, CustomStringConvertible, StringCodable {
  static let key = "trackTitle"
  let title: String
  var description: String { title }

  init(_ name: String) {
    self.title = name
  }

  static func == (lhs: TrackTitle, rhs: TrackTitle) -> Bool {
    lhs.title == rhs.title
  }
}

struct Username: Hashable, CustomStringConvertible, StringCodable {
  let name: String
  var description: String { name }

  init(_ name: String) {
    self.name = name
  }

  static func == (lhs: Username, rhs: Username) -> Bool { lhs.name == rhs.name }
}

// Marker trait
public protocol NonEmpty {
  init(_ value: String)
}

struct NonEmptyString: Equatable, Hashable, CustomStringConvertible, Codable,
  NonEmpty
{
  let value: String
  var description: String { value }

  init(_ value: String) {
    self.value = value
  }

  static func == (lhs: NonEmptyString, rhs: NonEmptyString) -> Bool {
    lhs.value == rhs.value
  }

  static func transform(raw: String) -> String? {
    validate(raw)?.value
  }

  static func validate(_ raw: String) -> NonEmptyString? {
    let trimmed = raw.trim()
    return !trimmed.isEmpty ? NonEmptyString(trimmed) : nil
  }
}

protocol StringCodable: Codable, CustomStringConvertible {
  init(_ value: String)
}

extension StringCodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(String.self).trim()
    if raw.isEmpty {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot initialize value from an empty string"
      )
    }
    self.init(raw)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

protocol NormalIntCodable: Codable, CustomStringConvertible {
  init(_ value: Int)
  var value: Int { get }
}

extension NormalIntCodable {
  var description: String { "\(value)" }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(Int.self)
    self.init(raw)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

protocol IntCodable: Codable {
  init(_ value: UInt64)
  var value: UInt64 { get }
}

extension IntCodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(UInt64.self)
    self.init(raw)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

protocol DoubleCodable: Codable {
  init(_ value: Double)
  var value: Double { get }
}

extension DoubleCodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    // Hack around Turf JSON BS that encodes a 0 or 1 to a boolean...
    do {
      let raw = try container.decode(Double.self)
      self.init(raw)
    } catch {
      let fromBool = try container.decode(Bool.self)
      let raw = fromBool ? 1.0 : 0.0
      self.init(raw)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

struct Mmsi: Hashable, CustomStringConvertible, Codable {
  static let key = "mmsi"
  let mmsi: String
  var description: String { mmsi }

  init(_ mmsi: String) {
    self.mmsi = mmsi
  }

  static func == (lhs: Mmsi, rhs: Mmsi) -> Bool { lhs.mmsi == rhs.mmsi }

  static func from(number: UInt64) -> Mmsi { Mmsi("\(number)") }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(UInt64.self)
    self.init("\(raw)")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(UInt64(mmsi))
  }
}

struct Coord: Hashable, Codable {
  let lng: Double
  let lat: Double
}

protocol WrappedString: Hashable, CustomStringConvertible, Codable {

}

extension String {
  func trim() -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
}
