import Foundation

class Files {
  static let documents = Files(baseUrl: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
  private let log = LoggerFactory.shared.system(Files.self)
  
  let baseUrl: URL
  
  var fileManager: FileManager { FileManager.default }
  
  init(baseUrl: URL) {
    self.baseUrl = baseUrl
    if !fileManager.isDirectory(url: baseUrl) {
      do {
        try fileManager.createDirectory(at: baseUrl, withIntermediateDirectories: true)
        log.info("Created directory \(baseUrl).")
      } catch {
        log.error("Failed to create directory \(baseUrl).")
      }
    }
  }
  
  func folder(name: String) -> Files {
    Files(baseUrl: baseUrl.appending(path: name, directoryHint: .isDirectory))
  }
  
  func save<T: Encodable>(_ t: T, to: String) throws {
    let destFile = baseUrl.appendingPathComponent(to)
    let data = try Json.shared.encoder.encode(t)
    try data.write(to: destFile)
  }

  func read<T: Decodable>(_ t: T.Type, from: String) throws -> T {
    let fromFile = baseUrl.appendingPathComponent(from)
    let data = try Data(contentsOf: fromFile)
    return try Json.shared.decoder.decode(t, from: data)
  }
  
  func listFilesOldestFirst() -> [URL] {
    return listFiles().sorted { file1, file2 in
      file1.created < file2.created
    }
  }
  
  func listFiles() -> [URL] {
    do {
      return try fileManager.contentsOfDirectory(
        at: baseUrl,
        includingPropertiesForKeys: [
          URLResourceKey.creationDateKey, URLResourceKey.isRegularFileKey,
        ], options: .skipsHiddenFiles)
    } catch {
      log.error("Failed to list files at \(baseUrl). \(error)")
    }
    return []
  }
}

class SyncFiles {
  let lockQueue: DispatchQueue
  
  static let locations = SyncFiles("locations")
  
  init(_ name: String) {
    lockQueue = DispatchQueue(label: "com.skogberglabs.boat.\(name)", attributes: [])
  }
}

extension FileManager {
  func isDirectory(url: URL) -> Bool {
    var isDirectory: ObjCBool = ObjCBool(false)
    self.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return isDirectory.boolValue
  }
}

extension URL {
  var created: Date {
    if let values = try? self.resourceValues(forKeys: [URLResourceKey.creationDateKey]),
      let created = values.creationDate
    {
      return created
    } else {
      return Date.distantPast
    }
  }

  var isFile: Bool {
    if let values = try? self.resourceValues(forKeys: [URLResourceKey.isRegularFileKey]),
      let isRegularFile = values.isRegularFile
    {
      return isRegularFile
    } else {
      return false
    }
  }

  var exists: Bool { do { return try self.checkResourceIsReachable() } catch { return false } }
}
