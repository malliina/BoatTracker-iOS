
import Foundation

enum LimitType: Decodable {
    case speedLimit
    case noWaves
    case noWindSurfing
    case noJetSkiing
    case noMotorPower
    case noAnchoring
    case noStopping
    case noAttachment
    case noOvertaking
    case noRendezVous
    case speedRecommendation
    
    func translate(lang: LimitTypes) -> String {
        switch self {
        case .speedLimit: return lang.speedLimit
        case .noWaves: return lang.noWaves
        case .noWindSurfing: return lang.noWindSurfing
        case .noJetSkiing: return lang.noJetSkiing
        case .noMotorPower: return lang.noMotorPower
        case .noAnchoring: return lang.noAnchoring
        case .noStopping: return lang.noStopping
        case .noAttachment: return lang.noAttachment
        case .noOvertaking: return lang.noOvertaking
        case .noRendezVous: return lang.noRendezVous
        case .speedRecommendation: return lang.speedRecommendation
        }
    }
    
    init(from decoder: Decoder) throws {
        let code = try decoder.singleValueContainer().decode(String.self)
        self = try LimitType.parse(input: code)
    }
    
    static func parse(input: String) throws -> LimitType {
        switch input {
        case "01": return .speedLimit
        case "02": return .noWaves
        case "03": return .noWindSurfing
        case "04": return .noJetSkiing
        case "05": return .noMotorPower
        case "06": return .noAnchoring
        case "07": return .noStopping
        case "08": return .noAttachment
        case "09": return .noOvertaking
        case "10": return .noRendezVous
        case "11": return .speedRecommendation
        default: throw JsonError.invalid("Unknown limit type: '\(input)'.", input)
        }
    }
}

struct RawLimitArea: Decodable {
    let types: String
    let limit: Double?
    let length: String?
    let responsible: String?
    let location: String?
    let fairwayName: String?
    let publishDate: String
    
    func validate() throws -> LimitArea {
        LimitArea(
            types: try types.components(separatedBy: ", ").map { try LimitType.parse(input: $0) },
            limit: limit.flatMap { $0.kmh },
            length: length.flatMap { Double($0)?.meters },
            responsible: responsible.flatMap { NonEmptyString.validate($0) },
            location: location.flatMap { NonEmptyString.validate($0) },
            fairwayName: fairwayName.flatMap { NonEmptyString.validate($0) },
            publishDate: publishDate
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case types = "RAJOITUSTY"
        case limit = "SUURUUS"
        case length = "PITUUS"
        case responsible = "MERK_VAST"
        case location = "NIMI_SIJAI"
        case fairwayName = "VAY_NIMISU"
        case publishDate = "IRROTUS_PV"
    }
}

struct LimitArea {
    let types: [LimitType]
    let limit: Speed?
    let length: Distance?
    let responsible: NonEmptyString?
    let location: NonEmptyString?
    let fairwayName: NonEmptyString?
    let publishDate: String
}
