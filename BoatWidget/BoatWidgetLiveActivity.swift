import ActivityKit
import SwiftUI
import WidgetKit

struct BoatWidgetLiveActivity: Widget {
  private func decodeImageOrDefault(str: String?) -> Image {
    if let encodedImage = str, let data = Data(base64Encoded: encodedImage),
      let uiImage = UIImage(data: data)
    {
      return Image(uiImage: uiImage)
    }
    return Image("boat-logo-40")
  }

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BoatWidgetAttributes.self) { context in
      // Lock screen/banner UI goes here
      HStack(spacing: 4) {
        Spacer()
        decodeImageOrDefault(str: context.state.image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 60, height: 60)
        VStack(spacing: 4) {
          Text("\(context.attributes.boatName) \(context.state.message)")
            .font(.headline)
          if let address = context.state.address {
            Text(address)
              .font(.subheadline)
          }
          HStack {
            Spacer()
            Text(context.state.duration.description)
            Spacer()
            Text(context.state.distance.description)
            Spacer()
          }
        }
        Spacer()
      }
      .activityBackgroundTint(Color.cyan)
      .activitySystemActionForegroundColor(Color.black)
      .padding(.vertical, 12)
      .padding(.horizontal, 16)
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
          HStack(spacing: 12) {
            decodeImageOrDefault(str: context.state.image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 84, height: 84)
            VStack {
              Text("\(context.attributes.boatName) \(context.state.message)")
              if let address = context.state.address {
                Text(address)
              }
            }
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

struct WidgetPreview {
  static let png =
    "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"
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
      duration: 123.seconds, address: "Road 1", coord: nil, image: WidgetPreview.png)
  }

  fileprivate static var onTheMove: BoatWidgetAttributes.ContentState {
    BoatWidgetAttributes.ContentState(
      message: "on the move!", distance: 24.meters,
      duration: 13.seconds, address: "Road 2", coord: nil, image: nil)
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
