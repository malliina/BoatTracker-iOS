import DGCharts
import Foundation
import SwiftUI

struct ChartLang {
  let tracks: TrackLang
  let formats: FormatsLang

  static func build(_ lang: Lang) -> ChartLang {
    ChartLang(tracks: lang.track, formats: lang.settings.formats)
  }
}

struct ChartsView: View {
  let lang: ChartLang
  let title: String
  let trackName: TrackName

  @EnvironmentObject var vm: ChartVM

  var body: some View {
    ChartRepresentable(lang: lang)
      .onAppear {
        vm.connect(track: trackName)
      }
      .onDisappear {
        vm.disconnect()
      }
      .navigationBarTitleDisplayMode(.large)
      .navigationTitle(title)
  }
}

struct ChartRepresentable: UIViewRepresentable {
  let lang: ChartLang
  @EnvironmentObject var vm: ChartVM

  init(lang: ChartLang) {
    self.lang = lang
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(lang: lang.tracks, isBoat: vm.data?.from.sourceType.isBoat ?? true)
  }

  func makeUIView(context: Context) -> LineChartView {
    let chart = LineChartView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    let coordinator = context.coordinator
    chart.data = LineChartData(dataSets: [coordinator.speedDataSet, coordinator.blueDataSet])
    chart.xAxis.valueFormatter = TimeFormatter(formatting: lang.formats)
    chart.xAxis.labelPosition = .bottom
    return chart
  }

  func updateUIView(_ uiView: LineChartView, context: Context) {
    if let event = vm.data {
      context.coordinator.updateDataSet(event: event)
      uiView.data?.notifyDataChanged()
      uiView.notifyDataSetChanged()
    }
  }

  class Coordinator {
    let seaBlue = UIColor(red: 0x00, green: 0x69, blue: 0x94)
    let speedDataSet: LineChartDataSet
    let blueDataSet: LineChartDataSet
    let lang: TrackLang

    init(lang: TrackLang, isBoat: Bool) {
      self.lang = lang
      let unit = isBoat ? "kn" : "km/h"
      speedDataSet = LineChartDataSet(entries: [], label: "\(lang.speed) (\(unit)")
      speedDataSet.colors = [.red]
      speedDataSet.circleRadius = 0
      speedDataSet.circleHoleRadius = 0
      blueDataSet = LineChartDataSet(
        entries: [], label: "\(isBoat ? lang.depth : lang.env.altitude) (m)")
      blueDataSet.colors = [seaBlue]
      blueDataSet.circleRadius = 0
      blueDataSet.circleHoleRadius = 0
    }

    func updateDataSet(event: CoordsData) {
      let isBoat = event.from.sourceType.isBoat
      let speedEntries = event.coords.map { c in
        ChartDataEntry(
          x: Double(c.time.millis), y: isBoat ? c.speed.knots : c.speed.kph,
          data: c.speed as AnyObject)
      }
      let speedUnit = isBoat ? "kn" : "km/h"
      speedDataSet.label = "\(lang.speed) (\(speedUnit))"
      speedDataSet.replaceEntries(speedDataSet.entries + speedEntries)

      let depthEntries = event.coords.map { c in
        ChartDataEntry(
          x: Double(c.time.millis), y: c.depthMeters.meters, data: c.depthMeters as AnyObject)
      }
      let altitudeEntries: [ChartDataEntry] = event.coords.compactMap { c in
        guard let altitude = c.altitude else { return nil }
        return ChartDataEntry(
          x: Double(c.time.millis), y: altitude.meters, data: c.altitude as AnyObject)
      }
      let blueMetric = isBoat ? lang.depth : lang.env.altitude
      blueDataSet.label = "\(blueMetric) (m)"
      let blueEntries = blueDataSet.entries + (isBoat ? depthEntries : altitudeEntries)
      blueDataSet.replaceEntries(blueEntries)
    }
  }

  typealias UIViewType = LineChartView
}

class ChartVM: ObservableObject {
  let log = LoggerFactory.shared.vc(ChartVM.self)

  @Published var data: CoordsData?

  private var socket: BoatSocket? = nil
  private var cancellables: [Task<(), Never>] = []
  
  func connect(track: TrackName) {
    let s = Backend.shared.openStandalone(track: track)
    socket = s
    let t = Task {
      for await coords in s.updates.values {
        await update(data: coords)
      }
    }
    cancellables = [t]
  }

  func disconnect() {
    socket?.close()
    socket = nil
    cancellables.forEach { t in
      t.cancel()
    }
    cancellables = []
  }

  func onCoords(event: CoordsData) async {
    await update(data: event)
  }

  @MainActor private func update(data: CoordsData) {
    self.data = data
  }
}
