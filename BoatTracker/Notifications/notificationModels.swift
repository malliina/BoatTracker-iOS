import Foundation

struct PushToken: Equatable, Hashable, CustomStringConvertible, StringCodable {
    let token: String
    var description: String { token }
    
    init(_ value: String) {
        self.token = value
    }
    
    static func == (lhs: PushToken, rhs: PushToken) -> Bool { lhs.token == rhs.token }
}

enum BoatState: String, Codable {
    case connected
    case disconnected
}

struct BoatNotification: Codable {
    let boatName: BoatName
    let state: BoatState
}
