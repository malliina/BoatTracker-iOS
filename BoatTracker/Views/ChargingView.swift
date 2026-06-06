import Foundation
import SwiftUI

struct ChargingView: View {
  let battery: Battery
  let lang: ChargingTimesLang
  
  var body: some View {
    HStack {
      ChargingIcon(batteryIcon(level: battery.chargeLevelPercentage))
      Text(String(format: "%.0f%%", battery.chargeLevelPercentage))
      Spacer().frame(width: TrackSummaryView.spacingBig)
      if let power = battery.chargingPower {
        ChargingIcon("bolt.circle")
        Text(power.description)
      } else {
        ChargingIcon("lines.measurement.horizontal")
        Text(battery.distanceToEmpty.formatKilometersInt)
      }
      if let toFull = battery.chargingTimeToFull {
        Spacer().frame(width: TrackSummaryView.spacingBig)
        ChargingIcon("clock.badge.checkmark")
        Text(String(format: "%.0f %@", toFull.seconds/60, lang.minutesShort))
      }
    }
  }
  
  func ChargingIcon(_ systemName: String) -> some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFit()
      .frame(width: 18, height: 18)
  }
  
  func batteryCategory(level: Double) -> String {
    if level >= 90 {
      return "100"
    } else if level >= 75 {
      return "75"
    } else if level >= 50 {
      return "50"
    } else if level >= 25 {
      return "25"
    } else {
      return "0"
    }
  }
  
  func batteryIcon(level: Double) -> String {
    let category = batteryCategory(level: level)
    return "battery.\(category)percent"
  }
}
