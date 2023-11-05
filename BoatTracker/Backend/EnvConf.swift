import Foundation

class EnvConf {
  static let shared = EnvConf()

  var server: String { "api.boat-tracker.com" }
  private var devBaseUrl: URL { URL(string: "http://localhost:9000")! }
  private var prodBaseUrl: URL { URL(string: "https://\(server)")! }
  //    var baseUrl: URL { devBaseUrl }
  var baseUrl: URL { prodBaseUrl }
}
