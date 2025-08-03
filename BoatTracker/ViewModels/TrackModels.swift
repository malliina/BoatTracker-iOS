import Foundation

struct SelectedTrack: Equatable {
  let track: TrackName?
  let selectedAt: Date
}

class ActiveTrack: ObservableObject {
  let log = LoggerFactory.shared.system(ActiveTrack.self)
  @Published var selectedTrack: SelectedTrack?

  func select(_ track: TrackName?) {
    log.info("Selecting \(track?.name ?? "no track")")
    selectedTrack = SelectedTrack(track: track, selectedAt: Date.now)
  }

  func clearIfOld() {
    guard let selected = selectedTrack, let name = selected.track else {
      return
    }
    let ageSeconds: TimeInterval = Date.now.timeIntervalSince(
      selected.selectedAt)
    let oneHour: TimeInterval = 3600
    if ageSeconds > oneHour {
      log.info(
        "Track \(name) no longer fresh after \(ageSeconds) seconds. Clearing state."
      )
      select(nil)
    } else {
      log.info(
        "Track \(name) still fresh after \(ageSeconds) seconds. Keeping it.")
    }
  }
}

extension Error {
  var describe: String {
    guard let appError = self as? AppError else {
      return "An error occurred. \(self)"
    }
    return appError.describe
  }
}
