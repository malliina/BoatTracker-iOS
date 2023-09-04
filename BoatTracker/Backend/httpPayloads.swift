
import Foundation

struct DisablePush: Codable {
    let token: PushToken
}

struct PushPayload: Codable {
    let token: PushToken
    let device: String
    
    init(_ token: PushToken) {
        self.token = token
        self.device = "ios"
    }
}

struct ChangeTrackTitle: Codable {
    let title: TrackTitle
}

struct ChangeBoatName: Codable {
    let boatName: BoatName
}

struct ChangeLanguage: Codable {
    let language: Language
}
