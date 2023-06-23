import Foundation

class ActiveTrack: ObservableObject {
    @Published var selectedTrack: TrackName?
}

extension Error {
    var describe: String {
        guard let appError = self as? AppError else { return "An error occurred. \(self)" }
        return appError.describe
    }
}
