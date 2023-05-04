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
    let tracks, duration, distance, topSpeed, avgSpeed, waterTemp, date, notAvailable, edit, rename, newName, cancel: String
    
    static func build(_ lang: Lang) -> SummaryLang {
        let track = lang.track
        let settings = lang.settings
        return SummaryLang(tracks: track.tracks, duration: track.duration, distance: track.distance, topSpeed: track.topSpeed, avgSpeed: track.avgSpeed, waterTemp: track.waterTemp, date: track.date, notAvailable: lang.messages.notAvailable, edit: settings.edit, rename: settings.rename, newName: settings.newName, cancel: settings.cancel)
    }
    
    static let preview = SummaryLang(tracks: "Tracks", duration: "Duration", distance: "Distance", topSpeed: "Top speed", avgSpeed: "Avg speed", waterTemp: "Water temp", date: "Date", notAvailable: "N/A", edit: "Edit", rename: "Rename", newName: "New name", cancel: "Cancel")
}

protocol TrackInfo {
    var duration: Duration { get }
    var distanceMeters: Distance { get }
    var topSpeed: Speed? { get }
    var avgSpeed: Speed? { get }
    var avgWaterTemp: Temperature? { get }
    var startDate: String { get }
    var sourceType: SourceType { get }
}

struct TrackInfo2: TrackInfo {
    let duration: Duration
    let distanceMeters: Distance
    let topSpeed: Speed?
    let avgSpeed: Speed?
    let avgWaterTemp: Temperature?
    let startDate: String
    let sourceType: SourceType
}

extension TrackRef: TrackInfo { }

struct TrackSummaryView: View {
    let track: TrackInfo
    let lang: SummaryLang
    let spacingBig: CGFloat = 36
    let verticalSpacing: CGFloat = 12
    var isBoat: Bool { track.sourceType.isBoat }
    var body: some View {
        VStack {
            HStack {
                Stat(lang.duration, track.duration)
                Spacer().frame(width: spacingBig)
                Stat(lang.distance, track.distanceMeters)
            }
            .padding(.vertical, verticalSpacing)
            HStack {
                Stat(lang.topSpeed, (isBoat ? track.topSpeed?.formattedKnots : track.topSpeed?.formattedKmh) ?? lang.notAvailable)
                Spacer().frame(width: spacingBig)
                Stat(lang.avgSpeed, (isBoat ? track.avgSpeed?.formattedKnots : track.avgSpeed?.formattedKmh) ?? lang.notAvailable)
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
        let info = TrackInfo2(duration: 1200.seconds, distanceMeters: 2000.meters, topSpeed: 40.knots, avgSpeed: 32.knots, avgWaterTemp: 14.celsius, startDate: "Today", sourceType: .boat)
        Group {
            TrackSummaryView(track: info, lang: SummaryLang.preview)
        }
    }
}
