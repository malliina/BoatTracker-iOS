import Foundation
import SwiftUI

struct StatsRepresentable: UIViewControllerRepresentable {
    let lang: Lang
    
    func makeUIViewController(context: Context) -> StatsVC {
        StatsVC(lang: lang)
    }
    
    func updateUIViewController(_ uiViewController: StatsVC, context: Context) {
    }
    
    typealias UIViewControllerType = StatsVC
}

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
        Task {
            display(text: lang.messages.loading)
            do {
                let stats = try await Backend.shared.http.stats()
                log.info("Got stats.")
                update(ss: stats)
            } catch {
                onError(error)
            }
        }
    }
    
    @MainActor private func update(ss: StatsResponse) {
        if ss.isEmpty {
            tableView.backgroundView = self.feedbackView(text: "")
        } else {
            tableView.backgroundView = nil
            stats = ss
        }
        tableView.reloadData()
    }
    
    func onError(_ err: Error) {
        log.error(err.describe)
        display(text: err.describe)
    }
    
    @MainActor func display(text: String) {
        let feedbackLabel = BoatLabel.build(text: text, alignment: .center, numberOfLines: 0)
        feedbackLabel.textColor = BoatColors.shared.feedback
        self.tableView.backgroundView = feedbackLabel
        self.stats = nil
        self.tableView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
