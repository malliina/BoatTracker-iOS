import Foundation

class BoatPreviews {
    static let shared = BoatPreviews()
    static let conf = try! BoatPreviews.shared.readLocalConf()
    
    let decoder = JSONDecoder()
    
    func readLocalConf() throws -> ClientConf {
        guard let fileUrl = Bundle.main.url(forResource: "conf", withExtension: "json") else {
            throw JsonError.missing("conf.json")
        }
        let data = try Data(contentsOf: fileUrl)
        return try decoder.decode(ClientConf.self, from: data)
    }
}
