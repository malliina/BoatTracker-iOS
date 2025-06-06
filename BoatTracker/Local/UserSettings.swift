import Foundation

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
    case .google: "Google"
    case .microsoft: "Microsoft"
    case .apple: "Apple"
    case .none: "Other"
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
    didSet {
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
    guard let languages = languages else { return nil }
    return selectLanguage(lang: currentLanguage, available: languages)
  }

  func lang(for language: Language) -> Lang? {
    guard let available = languages else { return nil }
    return selectLanguage(lang: language, available: available)
  }

  func selectLanguage(lang: Language, available: Languages) -> Lang {
    switch lang {
    case .fi: available.finnish
    case .se: available.swedish
    case .en: available.english
    }
  }
}
