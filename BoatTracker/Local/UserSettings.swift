//
//  UserProfile.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/03/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol LanguageChangedDelegate {
    func onLanguage(changed: Lang)
}

class UserSettings {
    static let shared = UserSettings()
    
    private let languageSubject = PublishSubject<Lang>()
    var languageChanges: Observable<Lang> {
        languageSubject.observeOn(MainScheduler.instance)
    }
    
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
                languageSubject.on(.next(lang))
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
    
    init() {
        
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
