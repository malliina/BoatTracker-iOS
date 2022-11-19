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

struct SummaryLang {
    let duration, distance, topSpeed, avgSpeed, waterTemp, date, notAvailable: String
    
    static func build(_ lang: Lang) -> SummaryLang {
        let track = lang.track
        return SummaryLang(duration: track.duration, distance: track.distance, topSpeed: track.topSpeed, avgSpeed: track.avgSpeed, waterTemp: track.waterTemp, date: track.date, notAvailable: lang.messages.notAvailable)
    }
}

struct TrackSummaryView: View {
    let track: TrackRef
    let lang: SummaryLang
    let spacingBig: CGFloat = 36
    let verticalSpacing: CGFloat = 12
    var body: some View {
        VStack {
            HStack {
                Stat(lang.duration, track.duration)
                Spacer().frame(width: spacingBig)
                Stat(lang.distance, track.distanceMeters)
            }
            .padding(.vertical, verticalSpacing)
            HStack {
                Stat(lang.topSpeed, track.topSpeed?.description ?? lang.notAvailable)
                Spacer().frame(width: spacingBig)
                Stat(lang.avgSpeed, track.avgSpeed?.description ?? lang.notAvailable)
            }
            .padding(.vertical, verticalSpacing)
            HStack {
                Stat(lang.waterTemp, track.avgWaterTemp?.description ?? lang.notAvailable)
                Spacer().frame(width: spacingBig)
                Stat(lang.date, track.startDate)
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
            StatView(label: "Label", value: "15.5", style: .large)
            StatView(label: "Label", value: "16.4", style: .small)
        }
    }
}
