import Foundation
import SwiftUI

struct StatSizing {
    let labelSize, valueSize, verticalSpace: CGFloat
}

struct StatView: View {
    let label: String
    let value: CustomStringConvertible
    let style: StatBoxStyle
    
    var color: BoatColor { BoatColor.shared }
    var sizing: StatSizing {
        switch style {
        case .small: return StatSizing(labelSize: 12, valueSize: 15, verticalSpace: 6)
        case .large: return StatSizing(labelSize: 14, valueSize: 17, verticalSpace: 12)
        }
    }
    
    var body: some View {
        VStack {
            Text(label)
                .font(.system(size: sizing.labelSize))
                .foregroundColor(color.secondaryText)
            Spacer()
                .frame(height: sizing.verticalSpace)
            Text(value.description)
                .font(.system(size: sizing.valueSize))
        }
    }
}

struct TrackSummaryView: View {
    let track: TrackRef
    let lang: Lang
    var trackLang: TrackLang { lang.track }
    var notAvailable: String { lang.messages.notAvailable }
    let spacingBig: CGFloat = 36
    let verticalSpacing: CGFloat = 12
    var body: some View {
        VStack {
            HStack {
                Stat(trackLang.duration, track.duration)
                Spacer().frame(width: spacingBig)
                Stat(trackLang.distance, track.distanceMeters)
            }
            .padding(.vertical, verticalSpacing)
            HStack {
                Stat(trackLang.topSpeed, track.topSpeed?.description ?? notAvailable)
                Spacer().frame(width: spacingBig)
                Stat(trackLang.avgSpeed, track.avgSpeed?.description ?? notAvailable)
            }
            .padding(.vertical, verticalSpacing)
            HStack {
                Stat(trackLang.waterTemp, track.avgWaterTemp?.description ?? notAvailable)
                Spacer().frame(width: spacingBig)
                Stat(trackLang.date, track.startDate)
            }
            .padding(.vertical, verticalSpacing)
        }
    }
    
    func Stat(_ label: String, _ value: CustomStringConvertible) -> some View {
        StatView(label: label, value: value, style: .large)
            .frame(minWidth: 120)
    }
}

struct TrackSummaryPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            StatView(label: "Label", value: "Value", style: .large)
            StatView(label: "Label", value: "Value", style: .small)
        }
    }
}
