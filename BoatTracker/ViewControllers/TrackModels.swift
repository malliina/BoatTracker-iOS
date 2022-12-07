import Foundation
import UIKit
import SwiftUI

protocol TracksDelegate {
    func onTrack(_ track: TrackName)
}

class ActiveTrack: ObservableObject {
    static let shared = ActiveTrack()
    
    @Published var selectedTrack: TrackName?
}

extension Error {
    var describe: String {
        guard let appError = self as? AppError else { return "An error occurred. \(self)" }
        return appError.describe
    }
}
