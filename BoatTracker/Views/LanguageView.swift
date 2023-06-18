import Foundation
import SwiftUI

struct SelectLanguageView<T>: View where T: LanguageProtocol {
    let lang: LanguageLang
    @ObservedObject var vm: T
    var languages: [LangInfo] {
        [
            LangInfo(language: Language.se, title: lang.swedish),
            LangInfo(language: Language.fi, title: lang.finnish),
            LangInfo(language: Language.en, title: lang.english)
        ]
    }
    var body: some View {
        BoatList(rowSeparator: .automatic) {
            ForEach(languages) { language in
                Button {
                    Task {
                        await vm.changeLanguage(to: language.language)
                    }
                } label: {
                    HStack {
                        Text(language.title)
                        Spacer()
                        if language.language == vm.currentLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.language)
    }
}

struct LanguageLang {
    let swedish, finnish, english, language: String
}

extension ProfileLang {
    var languages: LanguageLang { LanguageLang(swedish: swedish, finnish: finnish, english: english, language: language) }
}

struct LangInfo: Identifiable {
    let language: Language
    let title: String
    var id: String { language.rawValue }
}

protocol LanguageProtocol: ObservableObject {
    var currentLanguage: Language { get }
    func changeLanguage(to language: Language) async
}

class LanguageVM: LanguageProtocol {
    static let shared = LanguageVM()
    let log = LoggerFactory.shared.vc(LanguageVM.self)
    var settings: UserSettings { UserSettings.shared }
    private var current: Language { settings.currentLanguage }
    
    @Published var currentLanguage: Language
    
    init() {
        currentLanguage = UserSettings.shared.currentLanguage
    }
    
    func changeLanguage(to language: Language) async {
        do {
            let msg = try await http.changeLanguage(to: language)
            settings.userLanguage = language
            log.info(msg.message)
            await update(language: language)
        } catch {
            log.error("Failed to change language to \(language). \(error.describe)")
        }
    }
    
    @MainActor private func update(language: Language) {
        currentLanguage = language
    }
}

struct LanguagePreviews: BoatPreviewProvider, PreviewProvider {
    class PreviewsVM: LanguageProtocol {
        var currentLanguage: Language { Language.en }
        
        func changeLanguage(to language: Language) async {
        }
    }
    static var preview: some View {
        NavigationView {
            SelectLanguageView(lang: lang.profile.languages, vm: PreviewsVM())
        }
    }
}
