import ActivityKit
import SwiftUI
import WidgetKit

struct BoatWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BoatWidgetAttributes.self) { context in
      // Lock screen/banner UI goes here
      VStack(spacing: 4) {
        Text("\(context.attributes.boatName) \(context.state.message)")
        if let address = context.state.address {
          Text(address)
        }
        HStack {
          Spacer()
          Text(context.state.duration.description)
          Spacer()
          Text(context.state.distance.description)
          Spacer()
        }
      }
      .activityBackgroundTint(Color.cyan)
      .activitySystemActionForegroundColor(Color.black)
      .padding(.all, 12)
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          Text(context.state.duration.description)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.distance.description)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("\(context.attributes.boatName) \(context.state.message)")
          if let address = context.state.address {
            Text(address)
          }
        }
      } compactLeading: {
        Text(context.state.duration.description)
      } compactTrailing: {
        Text(context.state.distance.description)
      } minimal: {
        let kms = context.state.distance.kilometers
        if let km = Int(exactly: kms.rounded(.toNearestOrEven)) {
          Text("\(km)km")
        } else {
          Text(context.attributes.boatName.description)
        }
      }
      .contentMargins(.all, 20, for: .expanded)
      //      .widgetURL(URL(string: "https://www.apple.com"))
      //      .keylineTint(Color.red)
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
    BoatWidgetAttributes.ContentState(
      message: "connected!", distance: 10.meters,
      duration: 123.seconds, address: "Road 1")
  }

  fileprivate static var onTheMove: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(
      message: "on the move!", distance: 24.meters,
      duration: 13.seconds, address: "Road 2")
  }
}

#Preview("NotificationContent", as: .content, using: BoatWidgetAttributes.preview) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.connected
  BoatWidgetAttributes.ContentState.onTheMove
}

#Preview(
  "NotificationDynamicIslandCompact", as: .dynamicIsland(.compact),
  using: BoatWidgetAttributes.preview
) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.connected
  BoatWidgetAttributes.ContentState.onTheMove
}

#Preview(
  "NotificationDynamicIslandExpanded", as: .dynamicIsland(.expanded),
  using: BoatWidgetAttributes.preview
) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.connected
  BoatWidgetAttributes.ContentState.onTheMove
}

#Preview(
  "NotificationDynamicIslandMinimal", as: .dynamicIsland(.minimal),
  using: BoatWidgetAttributes.preview
) {
  BoatWidgetLiveActivity()
} contentStates: {
  BoatWidgetAttributes.ContentState.connected
  BoatWidgetAttributes.ContentState.onTheMove
}
