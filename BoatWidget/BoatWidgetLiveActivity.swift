import ActivityKit
import SwiftUI
import WidgetKit

struct BoatWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BoatWidgetAttributes.self) { context in
      // Lock screen/banner UI goes here
      VStack {
        Text("\(context.state.boatName)")
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
    BoatWidgetAttributes(name: "World")
  }
}

extension BoatWidgetAttributes.ContentState {
  fileprivate static var smiley: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(boatName: "Titanic", message: "connected!")
  }

  fileprivate static var starEyes: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(boatName: "Titanic", message: "on the move!")
  }
}

#Preview("Notification", as: .content, using: BoatWidgetAttributes.preview) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.smiley
  BoatWidgetAttributes.ContentState.starEyes
}
