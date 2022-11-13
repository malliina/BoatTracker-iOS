import Foundation
import Combine
import SwiftUI

typealias Row = Int

struct LangInfo {
    let language: Language
    let title: String
}

struct SelectLanguageRepresentable: UIViewControllerRepresentable {
    let lang: ProfileLang
    func makeUIViewController(context: Context) -> SelectLanguageVC {
        SelectLanguageVC(lang: lang)
    }
    
    func updateUIViewController(_ uiViewController: SelectLanguageVC, context: Context) {
    }
    
    typealias UIViewControllerType = SelectLanguageVC
}

class SelectLanguageVC: BaseTableVC, LanguageChangedDelegate {
    let log = LoggerFactory.shared.vc(SelectLanguageVC.self)
    let cellIdentifier = "LanguageCell"
    
    private var lang: ProfileLang
    private var current: Language {
        settings.currentLanguage
    }
    var langs: [Row: LangInfo] = [:]
    private var cancellable: AnyCancellable? = nil
    
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
        cancellable = settings.$languageChanges.sink { lang in
            if let lang = lang {
                self.onLanguage(changed: lang)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellable?.cancel()
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
        Task {
            do {
                let msg = try await Backend.shared.http.changeLanguage(to: language)
                settings.userLanguage = language
                log.info(msg.message)
            } catch {
                log.error("Failed to change language. \(error.describe)")
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        langs.count
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
