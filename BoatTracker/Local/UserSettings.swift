import Foundation

protocol LanguageChangedDelegate {
    func onLanguage(changed: Lang)
}

enum AuthProvider: String {
    case google = "google"
    case microsoft = "microsoft"
    case apple = "apple"
    case none = "none"
    
    static func parse(s: String) -> AuthProvider {
        AuthProvider(rawValue: s) ?? none
    }
    
    var name: String {
        switch self {
        case .google: return "Google"
        case .microsoft: return "Microsoft"
        case .apple: return "Apple"
        case .none: return "Other"
        }
    }
}

class UserSettings {
    static let shared = UserSettings()
    
    @Published var languageChanges: Lang? = nil
    
    var conf: ClientConf? = nil
    var languages: Languages? {
        conf?.languages
    }
    var profile: UserProfile? = nil {
        didSet  {
            userLanguage = profile?.language
        }
    }
    var userLanguage: Language? = nil {
        didSet {
            if userLanguage != oldValue, let lang = lang {
                languageChanges = lang
            }
        }
    }
    var currentLanguage: Language {
        userLanguage ?? Language.en
    }
    var lang: Lang? {
        get {
            guard let languages = languages else { return nil }
            return selectLanguage(lang: currentLanguage, available: languages)
        }
    }
    
    func lang(for language: Language) -> Lang? {
        guard let available = languages else { return nil }
        return selectLanguage(lang: language, available: available)
    }
    
    func selectLanguage(lang: Language, available: Languages) -> Lang {
        switch lang {
        case .fi: return available.finnish
        case .se: return available.swedish
        case .en: return available.english
        }
    }
}
