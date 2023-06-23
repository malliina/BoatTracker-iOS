import Foundation
import UIKit
import SwiftUI

struct AppAttribution: Codable {
    let title: String
    let text: String?
    let links: [TextAndUrl]
}

extension AppAttribution: Identifiable {
    var id: String { title }
}

struct AttributionInfo: Codable {
    let title: String
    let attributions: [AppAttribution]
}

class TextAndUrl: NSObject, Codable {
    let text: String
    let url: URL
    
    init(text: String, url: URL) {
        self.text = text
        self.url = url
    }
}
