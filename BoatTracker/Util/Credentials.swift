import Foundation

class Credentials {
    static func read(key: String) throws -> String {
        guard let file = Bundle.main.path(forResource: "Credentials", ofType: "plist") else { throw AppError.simple("Missing Credentials.plist") }
        guard let dict = NSDictionary(contentsOfFile: file) as? [String: AnyObject] else { throw AppError.simple("Invalid Credentials.plist") }
        return try readOrThrow(key: key, dict: dict)
    }
    
    static func readOrThrow(key: String, dict: [String: AnyObject]) throws -> String {
        guard let value = dict[key] as? String else { throw AppError.simple("Missing or invalid key '\(key)'.") }
        return value
    }
}
