import Foundation
import MapboxMaps

enum SourceType: Codable, Equatable {
  case vehicle
  case boat
  case other(name: String)

  var stringify: String {
    switch self {
    case .boat: return SourceType.boatKey
    case .vehicle: return SourceType.vehicleKey
    case .other(let name): return name
    }
  }
  var isBoat: Bool { self == SourceType.boat }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let s = try container.decode(String.self)
    self = try SourceType.parse(s: s)
  }
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(stringify)
  }

  static let boatKey = "boat"
  static let vehicleKey = "vehicle"
  static func parse(s: String) throws -> SourceType {
    switch s {
    case SourceType.vehicleKey: return .vehicle
    case SourceType.boatKey: return .boat
    default: return .other(name: s)
    }
  }
}

enum MarkType: Decodable {
  case unknown
  case lateral
  case cardinal

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let code = try container.decode(Int.self)
    self = try MarkType.parse(code: code)
  }

  func translate(lang: MarkTypeLang) -> String {
    switch self {
    case .unknown: return lang.unknown
    case .lateral: return lang.lateral
    case .cardinal: return lang.cardinal
    }
  }

  static func parse(code: Int) throws -> MarkType {
    switch code {
    case 0: return .unknown
    case 1: return .lateral
    case 2: return .cardinal
    default: throw JsonError.invalid("Unknown mark type: '\(code)'.", code)
    }
  }
}

enum FairwayType: Decodable {
  case navigation
  case anchoring
  case meetup
  case harborPool
  case turn
  case channel
  case coastTraffic
  case core
  case special
  case lock
  case confirmedExtra
  case helcom
  case pilot
  case unknown

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    do {
      let code = try container.decode(Int.self)
      self = try FairwayType.parse(code: code)
    } catch {
      self = .unknown
    }
  }

  func translate(lang: FairwayTypesLang) -> String {
    switch self {
    case .navigation: return lang.navigation
    case .anchoring: return lang.anchoring
    case .meetup: return lang.meetup
    case .harborPool: return lang.harborPool
    case .turn: return lang.turn
    case .channel: return lang.channel
    case .coastTraffic: return lang.coastTraffic
    case .core: return lang.core
    case .special: return lang.special
    case .lock: return lang.lock
    case .confirmedExtra: return lang.confirmedExtra
    case .helcom: return lang.helcom
    case .pilot: return lang.pilot
    case .unknown: return lang.navigation
    }
  }

  static func parse(code: Int) throws -> FairwayType {
    switch code {
    case 1: return .navigation
    case 2: return .anchoring
    case 3: return .meetup
    case 4: return .harborPool
    case 5: return .turn
    case 6: return .channel
    case 7: return .coastTraffic
    case 8: return .core
    case 9: return .special
    case 10: return .lock
    case 11: return .confirmedExtra
    case 12: return .helcom
    case 13: return .pilot
    default: throw JsonError.invalid("Unknown fairway type: '\(code)'.", code)
    }
  }

}

struct FairwayArea: Decodable {
  let owner: String
  //    let quality: QualityClass
  let fairwayType: FairwayType
  let fairwayDepth: Distance
  let harrowDepth: Distance
  //    let comparisonLevel: String
  //    let state: FairwayState
  let markType: MarkType?

  private enum CodingKeys: String, CodingKey {
    case owner = "OMISTAJA"
    case fairwayType = "VAYALUE_TY"
    case fairwayDepth = "VAYALUE_SY"
    case harrowDepth = "HARAUS_SYV"
    case markType = "MERK_LAJI"
  }
}

enum AidType: Decodable {
  case unknown
  case lighthouse
  case sectorLight
  case leadingMark
  case directionalLight
  case minorLight
  case otherMark
  case edgeMark
  case radarTarget
  case buoy
  case beacon
  case signatureLighthouse
  case cairn

  func translate(lang: AidTypeLang) -> String {
    switch self {
    case .lighthouse: return lang.lighthouse
    case .sectorLight: return lang.sectorLight
    case .leadingMark: return lang.leadingMark
    case .directionalLight: return lang.directionalLight
    case .minorLight: return lang.minorLight
    case .otherMark: return lang.otherMark
    case .edgeMark: return lang.edgeMark
    case .radarTarget: return lang.radarTarget
    case .buoy: return lang.buoy
    case .beacon: return lang.beacon
    case .signatureLighthouse: return lang.signatureLighthouse
    case .cairn: return lang.cairn
    case .unknown: return lang.unknown
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let code = try container.decode(Int.self)
    self = try AidType.parse(code: code)
  }

  static func parse(code: Int) throws -> AidType {
    switch code {
    case 0: return .unknown
    case 1: return .lighthouse
    case 2: return .sectorLight
    case 3: return .leadingMark
    case 4: return .directionalLight
    case 5: return .minorLight
    case 6: return .otherMark
    case 7: return .edgeMark
    case 8: return .radarTarget
    case 9: return .buoy
    case 10: return .beacon
    case 11: return .signatureLighthouse
    case 13: return .cairn
    default: throw JsonError.invalid("Unknown aid type: '\(code)'.", code)
    }
  }
}

enum NavMark: Decodable {
  case unknown
  case left
  case right
  case north
  case south
  case west
  case east
  case rock
  case safeWaters
  case special
  case notApplicable

  func translate(lang: NavMarkLang) -> String {
    switch self {
    case .left: return lang.left
    case .right: return lang.right
    case .north: return lang.north
    case .south: return lang.south
    case .west: return lang.unknown
    case .east: return lang.east
    case .rock: return lang.rock
    case .safeWaters: return lang.safeWaters
    case .special: return lang.special
    case .notApplicable: return lang.notApplicable
    case .unknown: return lang.unknown
    }
  }

  init(from decoder: Decoder) throws {
    let code = try decoder.singleValueContainer().decode(Int.self)
    self = try NavMark.parse(code: code)
  }

  static func parse(code: Int) throws -> NavMark {
    switch code {
    case 0: return .unknown
    case 1: return .left
    case 2: return .right
    case 3: return .north
    case 4: return .south
    case 5: return .west
    case 6: return .east
    case 7: return .rock
    case 8: return .safeWaters
    case 9: return .special
    case 99: return .notApplicable
    default: throw JsonError.invalid("Unknown mark type: '\(code)'.", code)
    }
  }
}

enum ConstructionInfo: Decodable {
  case buoyBeacon
  case iceBuoy
  case beaconBuoy
  case superBeacon
  case exteriorLight
  case dayBoard
  case helicopterPlatform
  case radioMast
  case waterTower
  case smokePipe
  case radarTower
  case churchTower
  case superBuoy
  case edgeCairn
  case compassCheck
  case borderMark
  case borderLineMark
  case channelEdgeLight
  case tower

  func translate(lang: ConstructionLang) -> String {
    switch self {
    case .buoyBeacon: return lang.buoyBeacon
    case .iceBuoy: return lang.iceBuoy
    case .beaconBuoy: return lang.beaconBuoy
    case .superBeacon: return lang.superBeacon
    case .exteriorLight: return lang.exteriorLight
    case .dayBoard: return lang.dayBoard
    case .helicopterPlatform: return lang.helicopterPlatform
    case .radioMast: return lang.radioMast
    case .waterTower: return lang.waterTower
    case .smokePipe: return lang.smokePipe
    case .radarTower: return lang.radarTower
    case .churchTower: return lang.churchTower
    case .superBuoy: return lang.superBuoy
    case .edgeCairn: return lang.edgeCairn
    case .compassCheck: return lang.compassCheck
    case .borderMark: return lang.borderMark
    case .borderLineMark: return lang.borderLineMark
    case .channelEdgeLight: return lang.channelEdgeLight
    case .tower: return lang.tower
    }
  }

  init(from decoder: Decoder) throws {
    let code = try decoder.singleValueContainer().decode(Int.self)
    self = try ConstructionInfo.parse(code: code)
  }

  private static func parse(code: Int) throws -> ConstructionInfo {
    switch code {
    case 1: return .buoyBeacon
    case 2: return .iceBuoy
    case 4: return .beaconBuoy
    case 5: return .superBeacon
    case 6: return .exteriorLight
    case 7: return .dayBoard
    case 8: return .helicopterPlatform
    case 9: return .radioMast
    case 10: return .waterTower
    case 11: return .smokePipe
    case 12: return .radarTower
    case 13: return .churchTower
    case 14: return .superBuoy
    case 15: return .edgeCairn
    case 16: return .compassCheck
    case 17: return .borderMark
    case 18: return .borderLineMark
    case 19: return .channelEdgeLight
    case 20: return .tower
    default: throw JsonError.invalid("Unknown construction type: '\(code)'.", code)
    }
  }
}

enum Flotation {
  case floating
  case solid
  case other(name: String)

  static func parse(input: String) -> Flotation {
    switch input {
    case "KELLUVA": return .floating
    case "KIINTE": return .solid
    default: return .other(name: input)
    }
  }
}

enum ZoneOfInfluence: String, Codable {
  case area = "A"
  case zone = "V"
  case zoneAndArea = "AV"
}

protocol BaseSymbol {
  var owner: String { get }
  var nameFi: NonEmptyString? { get }
  var nameSe: NonEmptyString? { get }
  var locationFi: NonEmptyString? { get }
  var locationSe: NonEmptyString? { get }
}

extension BaseSymbol {
  var hasLocation: Bool { return locationFi != nil || locationSe != nil }

  func translatedOwner(finnish: SpecialWords, translated: SpecialWords) -> String {
    switch owner {
    case finnish.transportAgency: return translated.transportAgency
    case finnish.defenceForces: return translated.defenceForces
    case finnish.portOfHelsinki: return translated.portOfHelsinki
    case finnish.cityOfEspoo: return translated.cityOfEspoo
    default: return owner
    }
  }

  func location(lang: Language) -> NonEmptyString? {
    switch lang {
    case .fi: return locationFi ?? locationSe
    case .se: return locationSe ?? locationFi
    case .en: return locationFi ?? locationSe
    }
  }

  func name(lang: Language) -> NonEmptyString? {
    switch lang {
    case .fi: return nameFi ?? nameSe
    case .se: return nameSe ?? nameFi
    case .en: return nameFi ?? nameSe
    }
  }
}

enum TrafficMarkType: Decodable {
  case speedLimit, noWaves, other

  init(from decoder: Decoder) throws {
    let code = try decoder.singleValueContainer().decode(Int.self)
    self = try TrafficMarkType.parse(code: code)
  }

  func translate(lang: LimitTypes) -> String {
    switch self {
    case .speedLimit: return lang.speedLimit
    case .noWaves: return lang.noWaves
    case .other: return lang.unknown
    }
  }

  private static func parse(code: Int) throws -> TrafficMarkType {
    switch code {
    case 6: return .noWaves
    case 11: return .speedLimit
    default: return .other
    }
  }
}

struct MinimalMarineSymbol: BaseSymbol, Decodable {
  let owner: String
  let nameFi, nameSe, locationFi, locationSe: NonEmptyString?
  let influence: ZoneOfInfluence?
  let trafficMarkType: TrafficMarkType?
  let limit: Double?

  var speedLimit: Speed? { trafficMarkType == .speedLimit ? limit?.kmh : nil }

  private enum CodingKeys: String, CodingKey {
    case owner = "OMISTAJA"
    case nameFi = "NIMIS"
    case nameSe = "NIMIR"
    case locationFi = "SIJAINTIS"
    case locationSe = "SIJAINTIR"
    case influence = "VAIKUTUSAL"
    case trafficMarkType = "VLM_LAJI"
    case limit = "RA_ARVO"
  }
}

struct StringBool: Codable {
  let value: Bool

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(String.self)
    if let parsed = StringBool.parse(raw: raw) {
      value = parsed
    } else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Unexpected string, must be K or E: '\(raw)'.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value ? "K" : "E")
  }

  static func parse(raw: String) -> Bool? {
    switch raw {
    case "K": return true
    case "E": return false
    default: return nil
    }
  }
}

struct IntBool: Codable {
  let value: Bool

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(Int.self)
    switch raw {
    case 1: value = true
    case 0: value = false
    default:
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Unexpected integer, must be 1 or 0: '\(raw)'.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value ? 1 : 0)
  }
}

class MarineSymbol: NSObject, BaseSymbol, Decodable {
  let owner: String
  let exteriorLight, topSign: Bool
  let nameFi, nameSe, locationFi, locationSe: NonEmptyString?
  let flotation: Flotation
  let state: String
  let lit: StringBool
  let aidType: AidType
  let navMark: NavMark
  let construction: ConstructionInfo?

  init(
    owner: String, exteriorLight: Bool, topSign: Bool, nameFi: NonEmptyString?,
    nameSe: NonEmptyString?, locationFi: NonEmptyString?, locationSe: NonEmptyString?,
    flotation: Flotation, state: String, lit: StringBool, aidType: AidType, navMark: NavMark,
    construction: ConstructionInfo?
  ) {
    self.owner = owner
    self.exteriorLight = exteriorLight
    self.topSign = topSign
    self.nameFi = nameFi
    self.nameSe = nameSe
    self.locationFi = locationFi
    self.locationSe = locationSe
    self.flotation = flotation
    self.state = state
    self.lit = lit
    self.aidType = aidType
    self.navMark = navMark
    self.construction = construction
  }

  static func boolNum(i: Int) throws -> Bool {
    switch i {
    case 0: return false
    case 1: return true
    default: throw JsonError.invalid("Unexpected integer, must be 1 or 0: '\(i)'.", i)
    }
  }

  static func boolString(s: String) throws -> Bool {
    switch s {
    case "K": return true
    case "E": return false
    default: throw JsonError.invalid("Unexpected string, must be K or E: '\(s)'.", s)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case owner = "OMISTAJA"
    case exteriorLight = "FASADIVALO"
    case topSign = "HUIPPUMERK"
    case nameFi = "NIMIS"
    case nameSe = "NIMIR"
    case locationFi = "SIJAINTIS"
    case locationSe = "SIJAINTIR"
    case flotation = "SUBTYPE"
    case state = "TILA"
    case lit = "VALAISTU"
    case aidType = "TY_JNR"
    case navMark = "NAVL_TYYP"
    case construction = "RAKT_TYYP"
  }

  required convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      owner: try container.decode(String.self, forKey: .owner),
      exteriorLight: try container.decode(IntBool.self, forKey: .exteriorLight).value,
      topSign: try container.decode(IntBool.self, forKey: .topSign).value,
      nameFi: try container.decodeIfPresent(NonEmptyString.self, forKey: .nameFi),
      nameSe: try container.decodeIfPresent(NonEmptyString.self, forKey: .nameSe),
      locationFi: try container.decodeIfPresent(NonEmptyString.self, forKey: .locationFi),
      locationSe: try container.decodeIfPresent(NonEmptyString.self, forKey: .locationSe),
      flotation: Flotation.parse(input: try container.decode(String.self, forKey: .flotation)),
      state: try container.decode(String.self, forKey: .state),
      lit: try container.decode(StringBool.self, forKey: .lit),
      aidType: (try? container.decode(AidType.self, forKey: .aidType)) ?? .unknown,
      navMark: (try? container.decode(NavMark.self, forKey: .navMark)) ?? .unknown,
      construction: try? container.decodeIfPresent(ConstructionInfo.self, forKey: .construction)
    )
  }
}

extension KeyedDecodingContainerProtocol {
  func trimmedNonEmpty(forKey key: Self.Key) throws -> String? {
    guard let s = try self.decodeIfPresent(String.self, forKey: key) else { return nil }
    let trimmed = s.trim()
    return trimmed.isEmpty ? nil : trimmed
  }
}

public protocol JSONBlankRepresentable: RawRepresentable {}

extension KeyedDecodingContainer {
  /// Decodes empty strings and other whitespace as nil.
  /// http://davelyon.net/2017/08/16/jsondecoder-in-the-real-world
  public func decodeIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer.Key) throws
    -> T? where T: Decodable & NonEmpty
  {
    if contains(key) {
      if let stringValue = try decodeIfPresent(String.self, forKey: key),
        let nonEmpty = NonEmptyString.transform(raw: stringValue)
      {
        return T.init(nonEmpty)
      }
    }
    return nil
  }
}

struct VesselsBody: Codable {
  let body: Vessels
}

struct Vessels: Codable {
  let vessels: [Vessel]
}

struct Vessel: Codable {
  static let headingKey = "heading"
  static let nameKey = "name"

  let mmsi: Mmsi
  let name: String
  let heading: Double?
  let cog: Double
  let sog: Speed
  //    let shipType: Int
  let draft: Distance
  let coord: CLLocationCoordinate2D
  let timestampMillis: Double
  let destination: String?
  let time: Timing

  var speed: Speed { sog }
}

struct VesselMeta: Codable {
  let mmsi: Mmsi
  let name: String
  let heading: Double
}

struct VesselProps: Codable {
  let mmsi: Mmsi
}

extension CLLocationCoordinate2D: Codable {
  private enum CodingKeys: CodingKey {
    case lng
    case lat
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let lng = try container.decode(Double.self, forKey: .lng)
    let lat = try container.decode(Double.self, forKey: .lat)
    self.init(latitude: lat, longitude: lng)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(latitude, forKey: .lat)
    try container.encode(longitude, forKey: .lng)
  }
}

struct CoordsBody: Codable {
  let body: CoordsData
}

struct CoordsData: Codable {
  let coords: [CoordBody]
  let from: TrackRef
}

protocol MeasuredCoord {
  var coord: CLLocationCoordinate2D { get }
  var speed: Speed { get }
}

struct CoordBody: Codable, MeasuredCoord {
  let coord: CLLocationCoordinate2D
  let boatTimeMillis: UInt64
  let speed: Speed
  let depthMeters: Distance
  let waterTemp: Temperature
  let outsideTemp: Temperature?
  let altitude: Distance?
  let time: Timing
}

struct TrackPoint: Codable {
  let speed: Speed
}

struct BoatPoint: Codable {
  let from: TrackRef
  let coord: CoordBody
}

struct TrackMeta: Codable {
  let trackName: TrackName
  let boatName: BoatName
  let username: Username
}

struct TracksResponse: Codable {
  let tracks: [TrackRef]
}

struct Timing: Codable {
  static let dateTimeKey = "dateTime"
  let date, time, dateTime: String
  let millis: UInt64
}

struct Times: Codable {
  let start, end: Timing
  let range: String
}

struct TrackRef: Codable, Identifiable {
  let trackName: TrackName
  let trackTitle: TrackTitle?
  let boatName: BoatName
  let username: Username

  let sourceType: SourceType
  let topSpeed: Speed?
  let avgSpeed: Speed?
  let distanceMeters: Distance
  let duration: Duration
  let avgWaterTemp: Temperature?
  let avgOutsideTemp: Temperature?
  let topPoint: CoordBody
  let times: Times

  var start: Date { Date(timeIntervalSince1970: Double(times.start.millis) / 1000) }
  var startDate: String { times.start.date }
  var id: String { trackName.name }
}

struct TrackResponse: Codable {
  let track: TrackRef
}

struct TrackStats: Codable {
  let points: Int
}

struct AccessToken: Equatable, Hashable, CustomStringConvertible, StringCodable {
  let token: String
  var description: String { token }

  init(_ value: String) {
    self.token = value
  }

  static func == (lhs: AccessToken, rhs: AccessToken) -> Bool { lhs.token == rhs.token }
}

struct AuthorizationCode: Equatable, Hashable, CustomStringConvertible, StringCodable {
  let code: String
  var description: String { code }

  init(_ value: String) {
    self.code = value
  }

  static func == (lhs: AuthorizationCode, rhs: AuthorizationCode) -> Bool { lhs.code == rhs.code }
}

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

  static func == (lhs: TrackName, rhs: TrackName) -> Bool { lhs.name == rhs.name }
}

struct TrackTitle: Hashable, CustomStringConvertible, StringCodable {
  static let key = "trackTitle"
  let title: String
  var description: String { title }

  init(_ name: String) {
    self.title = name
  }

  static func == (lhs: TrackTitle, rhs: TrackTitle) -> Bool { lhs.title == rhs.title }
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

struct NonEmptyString: Equatable, Hashable, CustomStringConvertible, Codable, NonEmpty {
  let value: String
  var description: String { value }

  init(_ value: String) {
    self.value = value
  }

  static func == (lhs: NonEmptyString, rhs: NonEmptyString) -> Bool { lhs.value == rhs.value }

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

protocol WrappedString: Hashable, CustomStringConvertible, Codable {

}

struct BackendInfo: Codable {
  let name: String
  let version: String
}

struct BoatResponse: Codable {
  let boat: Boat
}

struct Boat: Codable, Identifiable {
  let id: Int
  let name: BoatName
  let token: String
  let addedMillis: UInt64
}

struct UserToken: Equatable {
  let email: String
  let token: AccessToken
}

struct SimpleMessage: Codable {
  let message: String
}

enum Language: String, Codable {
  case fi = "fi-FI"
  case se = "sv-SE"
  case en = "en-US"

  static func parse(s: String) -> Language {
    Language(rawValue: s) ?? en
  }
}

struct UserContainer: Codable {
  let user: UserProfile
}

struct UserProfile: Codable {
  let id: Int
  let username: Username
  let email: String?
  let language: Language
  let boats: [Boat]
  let addedMillis: UInt64
}

struct TrackedBoat: Codable {
  let boatName: BoatName
  let trackName: TrackName
  let trackTitle: TrackTitle?
}

struct DateVal: StringCodable {
  let value: String
  var description: String { value }

  init(_ value: String) {
    self.value = value
  }
}

struct MonthVal: NormalIntCodable {
  let value: Int
  var description: String { "\(value)" }

  init(_ value: Int) {
    self.value = value
  }
}

struct YearVal: NormalIntCodable {
  let value: Int

  init(_ value: Int) {
    self.value = value
  }
}

struct Stats: Codable {
  let from, to: DateVal
  let days, trackCount: Int
  let distance: Distance
  let duration: Duration
}

struct MonthlyStats: Codable {
  let label: String
  let year: YearVal
  let month: MonthVal
  let days, trackCount: Int
  let distance: Distance
  let duration: Duration
}

extension MonthlyStats {
  var id: String { "\(year)-\(month)" }
}

struct YearlyStats: Codable {
  let year: YearVal
  let days, trackCount: Int
  let distance: Distance
  let duration: Duration
  let monthly: [MonthlyStats]
}

struct StatsResponse: Codable {
  let allTime: Stats
  let yearly: [YearlyStats]

  var isEmpty: Bool { allTime.trackCount == 0 }
}

struct TokenResponse: Codable {
  let email: String
  let idToken: AccessToken
}

struct RegisterCode: Codable {
  let code: AuthorizationCode
  let nonce: String
}
