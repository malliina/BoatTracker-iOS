import Foundation
import SwiftUI

struct PeriodStatLang {
    let distance, duration, days: String
}

struct PeriodStatView: View {
    let stat: YearlyStats
    let lang: PeriodStatLang
    var when: String { "\(stat.year)" }
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

struct PeriodStatPreviews: PreviewProvider {
    static let lang = PeriodStatLang(distance: "Distance", duration: "Duration", days: "Days")
    static var previews: some View {
        Group {
            PeriodStatView(stat: YearlyStats(year: YearVal(2022), days: 14, trackCount: 4, distance: Distance(meters: 1445), duration: Duration(1412), monthly: []), lang: lang)
        }
    }
}
