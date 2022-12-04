import Foundation
import SwiftUI
import Charts

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
    
    @StateObject var vm: ChartVM = ChartVM()
    
    var body: some View {
        ChartRepresentable(lang: lang, vm: vm)
            .onAppear() {
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
    @ObservedObject var vm: ChartVM
    
    init(lang: ChartLang, vm: ChartVM) {
        self.lang = lang
        self.vm = vm
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(lang: lang.tracks)
    }
    
    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        let coordinator = context.coordinator
        chart.data = LineChartData(dataSets: [coordinator.speedDataSet, coordinator.depthDataSet])
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
        let depthDataSet: LineChartDataSet
        
        init(lang: TrackLang) {
            speedDataSet = LineChartDataSet(entries: [], label: "\(lang.speed) (kn)")
            speedDataSet.colors = [ .red ]
            speedDataSet.circleRadius = 0
            speedDataSet.circleHoleRadius = 0
            depthDataSet = LineChartDataSet(entries: [], label: "\(lang.depth) (m)")
            depthDataSet.colors = [ seaBlue ]
            depthDataSet.circleRadius = 0
            depthDataSet.circleHoleRadius = 0
        }
        
        func updateDataSet(event: CoordsData) {
            let speedEntries = event.coords.map { c in
                ChartDataEntry(x: Double(c.time.millis), y: c.speed.knots, data: c.time.dateTime as AnyObject)
            }
            let depthEntries = event.coords.map { c in
                ChartDataEntry(x: Double(c.time.millis), y: c.depthMeters.meters, data: c.depthMeters as AnyObject)
            }
            speedDataSet.replaceEntries(speedDataSet.entries + speedEntries)
            let entries = speedDataSet.entries.count
            depthDataSet.replaceEntries(depthDataSet.entries + depthEntries)
        }
    }
    
    typealias UIViewType = LineChartView
}

class ChartVM: ObservableObject, BoatSocketDelegate {
    let log = LoggerFactory.shared.vc(ChartVM.self)
    
    @Published var data: CoordsData?
    
    private var socket: BoatSocket? = nil
    
    func connect(track: TrackName) {
        socket = Backend.shared.openStandalone(track: track, delegate: self)
    }
    
    func disconnect() {
        socket?.close()
        socket = nil
    }
    
    func onCoords(event: CoordsData) async {
        await update(data: event)
    }
    
    @MainActor private func update(data: CoordsData) {
        self.data = data
    }
}
