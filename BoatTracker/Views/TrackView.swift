import Foundation
import SwiftUI

struct TrackView: View {
    let lang: SummaryLang
    let track: TrackRef
    
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
            }
            .padding(.bottom, 8)
            HStack {
                Spacer()
                StatView(label: lang.distance, value: track.distanceMeters, style: .small)
                Spacer()
                StatView(label: lang.duration, value: track.duration, style: .small)
                Spacer()
                StatView(label: lang.topSpeed, value: track.topSpeed?.description ?? lang.notAvailable, style: .small)
                Spacer()
            }
        }
    }
}
