import Foundation

class Formatting {
    static let shared = Formatting()

    let minutes: DateComponentsFormatter
    let hours: DateComponentsFormatter

    /// https://stackoverflow.com/a/40321268
    init() {
        minutes = DateComponentsFormatter()
        minutes.zeroFormattingBehavior = .pad
        minutes.allowedUnits = [.minute, .second]
        hours = DateComponentsFormatter()
        hours.zeroFormattingBehavior = .pad
        hours.allowedUnits = [.minute, .second, .hour]
    }

    func format(duration: Duration) -> String {
        let seconds = duration.seconds
        let formatter = seconds >= 3600 ? hours : minutes
        return formatter.string(from: seconds) ?? "\(seconds) s"
    }
}
