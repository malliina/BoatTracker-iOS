//
//  ChartsVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 17/11/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import Charts
import UIKit
import RxSwift
import RxCocoa

class ChartsVC: UIViewController {
    let log = LoggerFactory.shared.vc(ChartsVC.self)
    
    let seaBlue = UIColor(hex: "#006994", alpha: 1.0)
    private var socket: BoatSocket? = nil
    let chart = LineChartView(frame: CGRect.zero)
    // Inits empty datasets whose data will be filled when coordinate events arrive
    let speedDataSet = LineChartDataSet(values: [], label: "Speed (kn)")
    let depthDataSet = LineChartDataSet(values: [], label: "Depth (m)")
    let track: TrackName
    
    init(track: TrackName) {
        self.track = track
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBackClicked(_:)))
        
        speedDataSet.colors = [ .red ]
        speedDataSet.circleRadius = 0
        speedDataSet.circleHoleRadius = 0
        
        depthDataSet.colors = [ seaBlue ]
        depthDataSet.circleRadius = 0
        depthDataSet.circleHoleRadius = 0
        
        chart.data = LineChartData(dataSets: [speedDataSet, depthDataSet])
        chart.xAxis.valueFormatter = TimeFormatter()
        chart.xAxis.labelPosition = .bottom
        view.addSubview(chart)
        chart.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
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
            ChartDataEntry(x: Double(c.boatTimeMillis), y: c.speed.knots, data: c.boatTime as AnyObject)
        }
        let depthEntries = event.coords.map { c in
            ChartDataEntry(x: Double(c.boatTimeMillis), y: c.depth.meters, data: c.depth as AnyObject)
        }
        onUiThread {
            self.navigationItem.title = event.from.startDate
            self.speedDataSet.values = self.speedDataSet.values + speedEntries
            self.depthDataSet.values = self.depthDataSet.values + depthEntries
            self.chart.data?.notifyDataChanged()
            self.chart.notifyDataSetChanged()
        }
    }
}

class TimeFormatter: IAxisValueFormatter {
    let formatter: DateFormatter = DateFormatter()

    init() {
        formatter.dateStyle = .none
        formatter.timeStyle = .short
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value / 1000)
        return formatter.string(from: date)
    }
}

extension UIColor {
    // I have copy-pasted this from a gist but forgotten the source
    convenience init(hex: String, alpha: CGFloat = 1) {
        assert(hex[hex.startIndex] == "#", "Expected hex string of format #RRGGBB")
        
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1  // skip #
        
        var rgb: UInt32 = 0
        scanner.scanHexInt32(&rgb)
        
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgb &   0xFF00) >>  8)/255.0,
            blue:  CGFloat((rgb &     0xFF)      )/255.0,
            alpha: alpha)
    }
}
