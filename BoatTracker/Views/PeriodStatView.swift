import Foundation
import SwiftUI

struct PeriodStatLang {
    let distance, duration, days: String
    
    static func build(_ lang: Lang) -> PeriodStatLang {
        let track = lang.track
        return PeriodStatLang(distance: track.distance, duration: track.duration, days: track.days)
    }
}

protocol StatInfo {
    var label: String { get }
    var distance: Distance { get }
    var duration: Duration { get }
    var days: Int { get }
}

extension YearlyStats: StatInfo {
    var label: String { "\(year.value)" }
}

extension MonthlyStats: StatInfo {
    
}

struct PeriodStatView: View {
    let stat: StatInfo
    let lang: PeriodStatLang
    var when: String { stat.label }
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text(when)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                Spacer()
            }
            HStack {
                Spacer()
                StatView(label: lang.distance, value: stat.distance, style: .small)
                Spacer()
                StatView(label: lang.duration, value: stat.duration, style: .small)
                Spacer()
                StatView(label: lang.days, value: stat.days, style: .small)
                Spacer()
            }
        }
    }
}

struct PeriodStatPreviews: BoatPreviewProvider, PreviewProvider {
    static var preview: some View {
        PeriodStatView(stat: YearlyStats(year: YearVal(2022), days: 14, trackCount: 4, distance: Distance(meters: 1445), duration: Duration(1412), monthly: []), lang: PeriodStatLang.build(lang))
    }
}
