import Foundation

class Files {
  let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

  func save<T: Encodable>(t: T, to: String) throws {
    let destFile = documentsUrl.appendingPathComponent(to)
    let data = try Json.shared.encoder.encode(t)
    try data.write(to: destFile)
  }

  func read<T: Decodable>(_ t: T.Type, from: String) throws -> T {
    let fromFile = documentsUrl.appendingPathComponent(from)
    let data = try Data(contentsOf: fromFile)
    return try Json.shared.decoder.decode(t, from: data)
  }
}
