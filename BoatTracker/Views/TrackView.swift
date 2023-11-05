import Foundation
import SwiftUI

struct TrackView: View {
  let lang: SummaryLang
  let track: TrackRef
  let onEdit: () -> Void

  var body: some View {
    VStack {
      HStack {
        Text(track.times.start.date)
          .padding(.trailing, 12)
        if let title = track.trackTitle?.title {
          Text(title)
            .foregroundColor(color.lightGray)
        }
        Spacer()
        Text(track.boatName.name)
          .font(.system(size: 14))
          .padding(.horizontal, 12)

      }
      .padding(.bottom, 8)
      HStack(spacing: 30) {
        StatView(label: lang.distance, value: track.distanceMeters, style: .small)
          .frame(maxWidth: .infinity)
        StatView(label: lang.duration, value: track.duration, style: .small)
          .frame(maxWidth: .infinity)
        StatView(
          label: lang.topSpeed,
          value: track.topSpeed?.formatted(isBoat: track.sourceType.isBoat) ?? lang.notAvailable,
          style: .small
        )
        .frame(maxWidth: .infinity)
      }.frame(maxWidth: 600)
    }
    .swipeActions(edge: .trailing) {
      Button(lang.edit) {
        onEdit()
      }
    }
  }
}
