//
//  StatsVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/08/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation

class StatsVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(StatsVC.self)
    
    let lang: Lang
    var stats: StatsResponse? = nil
    var state: ViewState = .loading
    
    init(lang: Lang) {
        self.lang = lang
        super.init(style: .plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = lang.labels.statistics
        tableView?.register(PeriodStatCell.self, forCellReuseIdentifier: PeriodStatCell.identifier)
        loadStats()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let stats = stats else { return 0 }
        return stats.yearly[section].monthly.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let stats = stats else { return 0 }
        // All time stats contributes to + 1
        return stats.yearly.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let stats = stats else { return nil }
//        let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: PeriodStatCell.identifier) as! PeriodStatCell
        let headerCell = tableView.dequeueReusableCell(withIdentifier: PeriodStatCell.identifier) as! PeriodStatCell
        headerCell.backgroundColor = BoatColors.shared.almostWhite
        headerCell.fill(year: stats.yearly[section], lang: lang)
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PeriodStatCell.identifier, for: indexPath) as! PeriodStatCell
        guard let stats = stats else { return cell }
        let monthly = stats.yearly[indexPath.section].monthly[indexPath.row]
        cell.fill(month: monthly, lang: lang)
        return cell
    }
    
    func loadStats() {
        display(text: lang.messages.loading)
        let _ = Backend.shared.http.stats().subscribe { (single) in
            switch single {
            case .success(let ss):
                self.log.info("Got stats.")
                self.onUiThread {
                    if ss.isEmpty {
                        self.tableView.backgroundView = self.feedbackView(text: "")
                    } else {
                        self.tableView.backgroundView = nil
                        self.stats = ss
                    }
                    self.tableView.reloadData()
                }
            case .failure(let err):
                self.onError(err)
            }
        }
    }
    
    func onError(_ err: Error) {
        log.error(err.describe)
        display(text: err.describe)
    }
    
    func display(text: String) {
        onUiThread {
            let feedbackLabel = BoatLabel.build(text: text, alignment: .center, numberOfLines: 0)
            feedbackLabel.textColor = BoatColors.shared.feedback
            self.tableView.backgroundView = feedbackLabel
            self.stats = nil
            self.tableView.reloadData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
