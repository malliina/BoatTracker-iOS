import ActivityKit

@MainActor
final class BoatLiveActivities: ObservableObject {
  static let shared = BoatLiveActivities()
  
  private let log = LoggerFactory.shared.system(BoatLiveActivities.self)
  
  func startLiveActivity() async throws {
    if #available(iOS 16.2, *) {
      if ActivityAuthorizationInfo().areActivitiesEnabled {
        do {
          let up = BoatWidgetAttributes(name: "hej")
          let initialState = BoatWidgetAttributes.ContentState(boatName: "Titanic", message: "On the move!", distance: 1.meters)
          let activity = try Activity.request(attributes: up, content: .init(state: initialState, staleDate: nil), pushType: .token)
          Task {
            await withTaskGroup(of: Void.self) { group in
              group.addTask { @MainActor in
                for await updateTokenData in activity.pushTokenUpdates {
                  let updateToken = updateTokenData.hexadecimalString
                  self.log.info("Got update token '\(updateToken)'.")
                }
              }
            }
          }
        }
      }
    } else {
      // Fallback on earlier versions
    }
  }
  
  func setup() {
    if #available(iOS 17.2, *) {
      Task {
        await withTaskGroup(of: Void.self) { group in
          let log = self.log
          let http = self.http
          group.addTask {
            @MainActor in
              for await startTokenData in Activity<BoatWidgetAttributes>.pushToStartTokenUpdates {
                let startToken = startTokenData.hexadecimalString
                do {
                  let _ = try await http.enableNotifications(payload: PushPayload(token: PushToken(startToken), device: .startLiveActivity))
                  log.info("Sent push to start token '\(startToken)' to backend.")
                } catch {
                  log.error("Failed to send push to start token '\(startToken)' to backend \(error).")
                }
              }
          }
          group.addTask {
            for await activity in Activity<BoatWidgetAttributes>.activityUpdates {
              log.info("Got update of Live Activity \(activity.id)...")
              Task {
                for await updateTokenData in activity.pushTokenUpdates {
                  let updateToken = updateTokenData.hexadecimalString
                  do {
                    let _ = try await http.enableNotifications(payload: PushPayload(token: PushToken(updateToken), device: .updateLiveActivity))
                    log.info("Sent update token '\(updateToken)' of Live Activity '\(activity.id)' to backend.")
                  } catch {
                    log.error("Failed to send update token '\(updateToken)' of Live Activity '\(activity.id)' to backend \(error).")
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

private extension Data {
    var hexadecimalString: String {
        self.reduce("") {
            $0 + String(format: "%02x", $1)
        }
    }
}

