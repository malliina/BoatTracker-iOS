import Foundation
import UIKit
import SwiftUI

struct AppAttribution: Codable {
    let title: String
    let text: String?
    let links: [Link]
}

extension AppAttribution: Identifiable {
    var id: String { title }
}

struct AttributionInfo: Codable {
    let title: String
    let attributions: [AppAttribution]
}

class Link: NSObject, Codable {
    let text: String
    let url: URL
    
    init(text: String, url: URL) {
        self.text = text
        self.url = url
    }
}
