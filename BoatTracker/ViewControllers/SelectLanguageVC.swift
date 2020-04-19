//
//  SelectLanguageVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 02/03/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

typealias Row = Int

struct LangInfo {
    let language: Language
    let title: String
}

class SelectLanguageVC: BaseTableVC, LanguageChangedDelegate {
    let log = LoggerFactory.shared.vc(SelectLanguageVC.self)
    let cellIdentifier = "LanguageCell"
    
    private var lang: ProfileLang
    private var current: Language {
        settings.currentLanguage
    }
    var langs: [Row: LangInfo] = [:]
    
    var disposeBag: DisposeBag? = nil
    
    init(lang: ProfileLang) {
        self.lang = lang
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        initData(lang: lang)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bag = DisposeBag()
        self.disposeBag = bag
        settings.languageChanges.subscribe(onNext: { (lang) in
            self.onLanguage(changed: lang)
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: bag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disposeBag = nil
    }
    
    func onLanguage(changed: Lang) {
        initData(lang: changed.profile, reload: true)
    }
    
    private func initData(lang: ProfileLang, reload: Bool = false) {
        navigationItem.title = lang.language
        self.langs = [
            0: LangInfo(language: Language.se, title: lang.swedish),
            1: LangInfo(language: Language.fi, title: lang.finnish),
            2: LangInfo(language: Language.en, title: lang.english)
        ]
        if reload {
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        guard let info = langs[indexPath.row] else { return cell }
        cell.textLabel?.text = info.title
        cell.accessoryType = info.language == current ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let info = langs[indexPath.row] else { return }
        changeLanguage(to: info.language)
    }
    
    func changeLanguage(to language: Language) {
        let _ = Backend.shared.http.changeLanguage(to: language).subscribe(onSuccess: { (msg) in
            self.settings.userLanguage = language
            self.log.info(msg.message)
        }) { (err) in
            self.log.error("Failed to change language. \(err.describe)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        langs.count
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
