import Foundation

class EnvConf {
  static let shared = EnvConf()

  var server: String { "api.boat-tracker.com" }
  private var devBaseUrl: URL { URL(string: "http://10.0.0.196:9000")! }
  private var prodBaseUrl: URL { URL(string: "https://\(server)")! }
  //    var baseUrl: URL { devBaseUrl }
  var baseUrl: URL { prodBaseUrl }
  var logsUrl: URL { URL(string: "https://logs.malliina.com")! }
}
