import ActivityKit
import SwiftUI
import WidgetKit

struct BoatWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BoatWidgetAttributes.self) { context in
      // Lock screen/banner UI goes here
      VStack {
        Text("\(context.attributes.boatName)")
        Text("\(context.state.message)")
      }
      .activityBackgroundTint(Color.cyan)
      .activitySystemActionForegroundColor(Color.black)
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          Text("Leading")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("Trailing")
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("Bottom \(context.state.message)")
          // more content
        }
      } compactLeading: {
        Text("L")
      } compactTrailing: {
        Text("T \(context.state.message)")
      } minimal: {
        Text(context.state.message)
      }
      .widgetURL(URL(string: "https://www.apple.com"))
      .keylineTint(Color.red)
    }
  }
}

extension BoatWidgetAttributes {
  fileprivate static var preview: BoatWidgetAttributes {
    BoatWidgetAttributes(boatName: BoatName("Boatsy"), trackName: TrackName("t1"))
  }
}

extension BoatWidgetAttributes.ContentState {
  fileprivate static var connected: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(message: "connected!", distance: 10.meters,
      duration: 123.seconds, address: "Road 1")
  }

  fileprivate static var onTheMove: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(message: "on the move!", distance: 24.meters,
      duration: 13.seconds, address: "Road 2")
  }
}

#Preview("Notification", as: .content, using: BoatWidgetAttributes.preview) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.connected
  BoatWidgetAttributes.ContentState.onTheMove
}
