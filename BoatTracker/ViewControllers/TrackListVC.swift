import Foundation
import UIKit

protocol TracksDelegate {
    /// Called on the main thread.
    func onTrack(_ track: TrackName)
}

class TrackListVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(TrackListVC.self)
    let cellKey = "TrackCell"
    
    var login: Bool = false
    
    private var tracks: [TrackRef] = []
    private var delegate: TracksDelegate? = nil
    
    let lang: Lang
    var settingsLang: SettingsLang { lang.settings }
    
    init(delegate: TracksDelegate?, login: Bool = false, lang: Lang) {
        self.delegate = delegate
        self.login = login
        self.lang = lang
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = lang.track.tracks
        tableView?.register(TrackCell.self, forCellReuseIdentifier: cellKey)
        loadTracks()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey, for: indexPath) as! TrackCell
        cell.fill(track: tracks[indexPath.row], lang: lang)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = UIContextualAction(style: .normal, title: settingsLang.edit) { (action, view, bool) in
            self.showEditTitlePopup(tableView, at: indexPath, track: self.tracks[indexPath.row])
        }
        return UISwipeActionsConfiguration(actions: [item])
    }
    
    func showEditTitlePopup(_ tableView: UITableView, at indexPath: IndexPath, track: TrackRef) {
        let popup = UIAlertController(title: settingsLang.rename, message: settingsLang.newName, preferredStyle: .alert)
        popup.addTextField { textField in
            textField.text = track.trackTitle?.title
        }
        let okAction = UIAlertAction(title: settingsLang.rename, style: .default) { (a) in
            guard let textField = (popup.textFields ?? []).headOption(),
                let newName = textField.text, !newName.isEmpty else { return }
            Task {
                do {
                    let updatedTrack = try await self.backend.http.changeTrackTitle(name: track.trackName, title: TrackTitle(newName))
                    self.tracks[indexPath.row] = updatedTrack.track
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                } catch {
                    self.log.error("Unable to rename. \(error.describe)")
                }
            }
        }
        popup.addAction(okAction)
        popup.addAction(UIAlertAction(title: settingsLang.cancel, style: .cancel, handler: nil))
        present(popup, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = tracks[indexPath.row]
        self.delegate?.onTrack(selected.trackName)
        goBack()
    }
    
    func loadTracks() {
        display(text: lang.messages.loading)
        Task {
            do {
                let ts = try await backend.http.tracks()
                log.info("Got \(ts.count) tracks.")
                update(ts: ts)
            } catch {
                onError(error)
            }
        }
    }
    
    @MainActor private func update(ts: [TrackRef]) {
        if ts.isEmpty {
            tableView.backgroundView = self.feedbackView(text: self.lang.settings.noTracksHelp)
        } else {
            tableView.backgroundView = nil
            tracks = ts
        }
        tableView.reloadData()
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
            self.tracks = []
            self.tableView.reloadData()
        }
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}

extension Error {
    var describe: String {
        guard let appError = self as? AppError else { return "An error occurred. \(self)" }
        return appError.describe
    }
}
