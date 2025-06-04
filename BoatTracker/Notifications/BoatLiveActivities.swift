import ActivityKit

final class BoatLiveActivities: ObservableObject {
  static let shared = BoatLiveActivities()

  private let log = LoggerFactory.shared.system(BoatLiveActivities.self)
  
  private var backend: Backend { Backend.shared }

  func setup() {
    Task {
      // Must have token to enable notifications
      for await _ in Auth.shared.tokens.first().values {
        setupAuthed()
      }
    }
  }
  
  private func setupAuthed() {
    if #available(iOS 17.2, *) {
      let deviceId = BoatPrefs.shared.deviceId
      Task {
        await withTaskGroup(of: Void.self) { group in
          let log = self.log
          let http = self.http
          group.addTask {
            @MainActor in
            for await startTokenData in Activity<BoatWidgetAttributes>.pushToStartTokenUpdates {
              let startToken = startTokenData.hexadecimalString
              do {
                let _ = try await http.enableNotifications(
                  payload: PushPayload(
                    token: PushToken(startToken), device: .startLiveActivity, deviceId: deviceId,
                    liveActivityId: nil, trackName: nil))
                let deviceId = BoatPrefs.shared.deviceId
                log.info(
                  "Sent push to start token '\(startToken)' to backend for device '\(deviceId)'.")
              } catch {
                log.error("Failed to send push to start token '\(startToken)' to backend \(error).")
              }
            }
          }
          group.addTask {
            for await activity in Activity<BoatWidgetAttributes>.activityUpdates {
              let activityId = activity.id
              log.info("Got update of Live Activity '\(activityId)'...")
              Task {
                for await updateTokenData in activity.pushTokenUpdates {
                  let updateToken = updateTokenData.hexadecimalString
                  do {
                    let _ = try await self.backend.updateToken()
                    let _ = try await http.enableNotifications(
                      payload: PushPayload(
                        token: PushToken(updateToken), device: .updateLiveActivity,
                        deviceId: deviceId, liveActivityId: activityId,
                        trackName: activity.attributes.trackName))
                    log.info(
                      "Sent update token '\(updateToken)' of Live Activity '\(activityId)' for device '\(deviceId)' to backend."
                    )
                  } catch {
                    log.error(
                      "Failed to send update token '\(updateToken)' of Live Activity '\(activityId)' to backend \(error)."
                    )
                  }
                }
              }
              Task {
                for await state in activity.activityStateUpdates {
                  switch state {
                  case .active:
                    log.info("Activity \(activityId) active")
                  case .ended:
                    log.info("Activity \(activityId) ended")
                  case .dismissed:
                    log.info("Activity \(activityId) dismissed")
                  case .stale:
                    log.info("Activity \(activityId) stale")
                  default:
                    log.info("Unknown activity state for \(activityId)")
                  }
                }
              }
            }
          }
        }
      }
    } else {
      log.info("Live Activities not supported.")
    }
  }
  
//  func startLiveActivity() async throws {
//    if #available(iOS 16.2, *) {
//      if ActivityAuthorizationInfo().areActivitiesEnabled {
//        do {
//          let up = BoatWidgetAttributes(boatName: BoatName("Boatsy"), trackName: TrackName("t1"))
//          let initialState = BoatWidgetAttributes.ContentState(
//            message: "On the move!", distance: 1.meters,
//            duration: 10.seconds, address: "Road 1")
//          let activity = try Activity.request(
//            attributes: up, content: .init(state: initialState, staleDate: nil), pushType: .token)
//          // This is not necessary, since the same push token updates are published in the below setup() function
//          Task {
//            await withTaskGroup(of: Void.self) { group in
//              group.addTask { @MainActor in
//                for await updateTokenData in activity.pushTokenUpdates {
//                  let updateToken = updateTokenData.hexadecimalString
//                  self.log.info("Got update token '\(updateToken)'.")
//                }
//              }
//            }
//          }
//        }
//      }
//    } else {
//      // Fallback on earlier versions
//    }
//  }
}

extension Data {
  fileprivate var hexadecimalString: String {
    self.reduce("") {
      $0 + String(format: "%02x", $1)
    }
  }
}
