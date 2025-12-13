import ActivityKit

final class BoatLiveActivities: ObservableObject {
  static let shared = BoatLiveActivities()

  private let log = LoggerFactory.shared.system(BoatLiveActivities.self)

  private var backend: Backend { Backend.shared }

  func setup() {
    Task {
      await setupAuthed()
    }
  }

  func setupAuthed() async {
    let launches = BoatPrefs.shared.launch().joined(separator: ", ")
    log.info("Last five launches: \(launches)")
    if #available(iOS 17.2, *) {
      let deviceId = BoatPrefs.shared.deviceId
      await withTaskGroup(of: Void.self) { group in
        let log = self.log
        let http = self.http
        group.addTask {
          log.info("Listening to push to start token updates...")
          for await startTokenData in Activity<BoatWidgetAttributes>.pushToStartTokenUpdates {
            let startToken = startTokenData.hexadecimalString
            do {
              if (try await self.backend.updateToken()) != nil {
                let _ = try await http.enableNotifications(
                  payload: PushPayload(
                    token: PushToken(startToken), device: .startLiveActivity, deviceId: deviceId,
                    liveActivityId: nil, trackName: nil))
                let deviceId = BoatPrefs.shared.deviceId
                log.info(
                  "Sent push to start token '\(startToken)' to backend for device '\(deviceId)'.")
              } else {
                log.info("Not sending push to start token '\(startToken)' to backend as there is no valid user token.")
              }
            } catch {
              log.error("Failed to save push to start token '\(startToken)' to backend \(error).")
            }
          }
        }
        group.addTask {
          for await activity in Activity<BoatWidgetAttributes>.activityUpdates {
            let activityId = activity.id
            log.info("Got start or update of Live Activity '\(activityId)'...")
            await withTaskGroup(of: Void.self) { activityGroup in
              activityGroup.addTask {
                for await updateTokenData in activity.pushTokenUpdates {
                  let updateToken = updateTokenData.hexadecimalString
                  do {
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
              activityGroup.addTask {
                for await state in activity.activityStateUpdates {
                  switch state {
                  case .active:
                    log.info("Activity \(activityId) active.")
                  case .ended:
                    log.info("Activity \(activityId) ended.")
                  case .dismissed:
                    log.info("Activity \(activityId) dismissed.")
                  case .stale:
                    log.info("Activity \(activityId) stale.")
                  default:
                    log.info("Unknown activity state for \(activityId).")
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
}

extension Data {
  fileprivate var hexadecimalString: String {
    self.reduce("") {
      $0 + String(format: "%02x", $1)
    }
  }
}
