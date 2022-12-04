import Foundation
import Charts
import UIKit
import SwiftUI

struct ChartsRepresentable: UIViewControllerRepresentable {
    let track: TrackName
    let lang: Lang
    
    func makeUIViewController(context: Context) -> ChartsVC {
        ChartsVC(track: track, lang: lang)
    }
    
    func updateUIViewController(_ uiViewController: ChartsVC, context: Context) {
        
    }
    
    typealias UIViewControllerType = ChartsVC
}

class ChartsVC: UIViewController {
    let log = LoggerFactory.shared.vc(ChartsVC.self)
    
    let seaBlue = UIColor(red: 0x00, green: 0x69, blue: 0x94)
    //let seaBlue = UIColor(hex: "#006994", alpha: 1.0)
    private var socket: BoatSocket? = nil
    let chart = LineChartView(frame: CGRect.zero)
    // Inits empty datasets whose data will be filled when coordinate events arrive
    let speedDataSet: LineChartDataSet
    let depthDataSet: LineChartDataSet
    let track: TrackName
    let lang: Lang
    
    init(track: TrackName, lang: Lang) {
        self.track = track
        self.lang = lang
        speedDataSet = LineChartDataSet(entries: [], label: "\(lang.track.speed) (kn)")
        depthDataSet = LineChartDataSet(entries: [], label: "\(lang.track.depth) (m)")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            let navbar = navigationController?.navigationBar
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithDefaultBackground()
            navbar?.standardAppearance = navBarAppearance
            navbar?.scrollEdgeAppearance = navBarAppearance
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: lang.settings.back, style: .plain, target: self, action: #selector(goBackClicked(_:)))
        
        speedDataSet.colors = [ .red ]
        speedDataSet.circleRadius = 0
        speedDataSet.circleHoleRadius = 0
        
        depthDataSet.colors = [ seaBlue ]
        depthDataSet.circleRadius = 0
        depthDataSet.circleHoleRadius = 0
        
        chart.data = LineChartData(dataSets: [speedDataSet, depthDataSet])
        chart.xAxis.valueFormatter = TimeFormatter(formatting: lang.settings.formats)
        chart.xAxis.labelPosition = .bottom
        view.addSubview(chart)
        chart.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        connect(track: track)
    }
    
    func connect(track: TrackName) {
        socket = Backend.shared.openStandalone(track: track, delegate: self)
    }
    
    @objc func goBackClicked(_ sender: UIBarButtonItem) {
        socket?.close()
        goBack()
    }
}

extension ChartsVC: BoatSocketDelegate {
    func onCoords(event: CoordsData) {
        let speedEntries = event.coords.map { c in
            ChartDataEntry(x: Double(c.time.millis), y: c.speed.knots, data: c.time.dateTime as AnyObject)
        }
        let depthEntries = event.coords.map { c in
            ChartDataEntry(x: Double(c.time.millis), y: c.depthMeters.meters, data: c.depthMeters as AnyObject)
        }
        onUiThread {
            self.navigationItem.title = event.from.trackTitle?.description ?? event.from.startDate
            self.speedDataSet.replaceEntries(self.speedDataSet.entries + speedEntries)
            self.depthDataSet.replaceEntries(self.depthDataSet.entries + depthEntries)
            self.chart.data?.notifyDataChanged()
            self.chart.notifyDataSetChanged()
        }
    }
}

extension ChartsVC: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // TODO show details
    }
}

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
       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }
}
