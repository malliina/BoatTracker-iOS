import Foundation

struct DisablePush: Codable {
  let token: PushToken
}

enum TokenType: String, Codable {
  case notification = "ios"
  case startLiveActivity = "ios-activity-start"
  case updateLiveActivity = "ios-activity-update"
}

struct PushPayload: Codable {
  let token: PushToken
  let device: TokenType
  let deviceId: String?
  let liveActivityId: String?
  let trackName: TrackName?
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
