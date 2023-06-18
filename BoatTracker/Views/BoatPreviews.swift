import Foundation
import SwiftUI

class BoatPreviews {
    static let shared = BoatPreviews()
    static let conf = try! BoatPreviews.shared.readLocalConf()
    
    let devices = ["iPhone 13 mini", "iPad Pro (11-inch) (4th generation)"]
    
    let decoder = JSONDecoder()
    
    func readLocalConf() throws -> ClientConf {
        guard let fileUrl = Bundle.main.url(forResource: "conf", withExtension: "json") else {
            throw JsonError.missing("conf.json")
        }
        let data = try Data(contentsOf: fileUrl)
        return try decoder.decode(ClientConf.self, from: data)
    }
}

protocol BoatPreviewProvider: PreviewProvider {
    associatedtype Preview: View
    static var preview: Preview { get }
}

extension BoatPreviewProvider {
    static var previews: some View {
        ForEach(BoatPreviews.shared.devices, id: \.self) { deviceName in
            Group {
                preview
            }
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
