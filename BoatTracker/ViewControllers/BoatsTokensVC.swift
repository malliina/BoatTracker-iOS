//
//  BoatsTokensVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension BoatTokensVC: NotificationPermissionDelegate {
    func didRegister(_ token: PushToken) {
        if let token = self.boatSettings.pushToken {
            log.info("Permission granted.")
            registerWithToken(token: token)
        } else {
            log.info("Access granted, but no token available.")
        }
    }
    
    func didFailToRegister(_ error: Error) {
        onUiThread {
            self.onOff?.isOn = false
        }
        let error = AppError.simple("The user did not grant permission to send notifications")
        log.error(error.describe)
    }
    
    func registerNotifications() {
        notifications.permissionDelegate = self
        if let token = boatSettings.pushToken {
            log.info("Registering with previously saved push token...")
            registerWithToken(token: token)
        } else {
            log.info("No saved push token. Asking for permission...")
            notifications.initNotifications(UIApplication.shared)
        }
    }
    
    func disableNotifications() {
        if let token = boatSettings.pushToken {
            http.disableNotifications(token: token).subscribe { (event) in
                switch event {
                case .success(_): self.log.info("Disabled notifications with backend.")
                case .error(let err): self.log.error("Failed to disable notifications with backend. \(err.describe)")
                }
            }.disposed(by: bag)
        }
        notifications.disableNotifications()
    }
    
    func registerWithToken(token: PushToken) {
        http.enableNotifications(token: token).subscribe { (event) in
            switch event {
            case .success(_): self.log.info("Enabled notifications with backend.")
            case .error(let err): self.log.error(err.describe)
            }
        }.disposed(by: bag)
    }
}

class BoatTokensVC: BaseTableVC {
    let log = LoggerFactory.shared.vc(BoatTokensVC.self)
    let cellKey = "BoatCell"
    let notificationsKey = "NotificationsCell"
    let boatSettings = BoatPrefs.shared
    let http = Backend.shared.http
    let notifications = BoatNotifications.shared
    let bag = DisposeBag()
    
    var profile: UserProfile? = nil
    var onOff: UISwitch?
    var loadError: Error? = nil
    let lang: Lang
    var settingsLang: SettingsLang { return lang.settings }
    
    init(lang: Lang) {
        self.lang = lang
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didToggleNotifications(_ uiSwitch: UISwitch) {
        if uiSwitch.isOn {
            registerNotifications()
        } else {
            disableNotifications()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = lang.track.boats
        tableView?.register(BoatTokenCell.self, forCellReuseIdentifier: BoatTokenCell.identifier)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: notificationsKey)
        onOff = BoatSwitch { (uiSwitch) in
            self.didToggleNotifications(uiSwitch)
        }
        onOff?.isOn = boatSettings.pushToken != nil
        loadProfile()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: notificationsKey, for: indexPath)
            cell.textLabel?.text = settingsLang.notifications
            cell.accessoryView = onOff
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: BoatTokenCell.identifier, for: indexPath)
            if let boat = profile?.boats[indexPath.row], let cell = cell as? BoatTokenCell {
                cell.fill(boat: boat.name, token: boat.token, lang: lang.settings)
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard loadError == nil else { return 0 }
        switch section {
        case 0: return 1
        case 1: return profile?.boats.count ?? 0
        default: return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 8
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0: return UIView()
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0: return footerView(text: settingsLang.notificationsText)
        case 1: return footerView(text: settingsLang.tokenText)
        default: return nil
        }
    }
    
    private func footerView(text: String) -> BoatTextView {
        let textView = BoatTextView(text: text, font: UIFont.systemFont(ofSize: 16))
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let popup = UIAlertController(title: settingsLang.renameBoat, message: settingsLang.newName, preferredStyle: .alert)
        popup.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: settingsLang.rename, style: .default) { (a) in
            guard let textField = (popup.textFields ?? []).headOption(),
                let newName = textField.text, !newName.isEmpty,
                let boat = self.profile?.boats[indexPath.row] else { return }
            let _ = Backend.shared.http.renameBoat(boat: boat.id, newName: BoatName(newName)).subscribe { (single) in
                switch single {
                case .success(let boat):
                    self.loadProfile()
                    self.log.info("Renamed to '\(boat.name)'.")
                case .error(let err):
                    self.log.error("Unable to rename. \(err.describe)")
                }
            }
        }
        popup.addAction(okAction)
        popup.addAction(UIAlertAction(title: settingsLang.cancel, style: .cancel, handler: nil))
        present(popup, animated: true, completion: nil)
    }
    
    func loadProfile() {
        let _ = Backend.shared.http.profile().subscribe { (single) in
            self.onUiThread {
                self.onProfile(single)
            }
        }
    }
    
    func onProfile(_ single: SingleEvent<UserProfile>) {
        switch single {
        case .success(let p):
            loadError = nil
            profile = p
            log.info("Got profile for user \(p.username).")
            tableView.backgroundView = nil
            tableView.reloadData()
        case .error(let err):
            loadError = err
            tableView.backgroundView = feedbackView(text: self.lang.messages.failedToLoadProfile)
            log.error("Unable to load profile. \(err.describe)")
        }
    }
}
