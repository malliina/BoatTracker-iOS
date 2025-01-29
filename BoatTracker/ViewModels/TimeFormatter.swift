import DGCharts
import Foundation

class TimeFormatter: AxisValueFormatter {
  let formatter: DateFormatter

  init(formatting: FormatsLang) {
    let formatter = DateFormatter()
    formatter.dateFormat = formatting.timeShort
    self.formatter = formatter
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let date = Date(timeIntervalSince1970: value / 1000)
    return formatter.string(from: date)
  }
}

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    self.init(
      red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0,
      blue: CGFloat(blue) / 255.0,
      alpha: 1.0)
  }
}
