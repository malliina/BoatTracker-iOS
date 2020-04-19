////
//// Created by Michael Skogberg on 25.12.2019.
//// Copyright (c) 2019 Michael Skogberg. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//
//struct LanguageCell: View {
//    let language: LangInfo
//    @Binding var selectedLanguage: Language
//
//    var body: some View {
//        HStack {
//            Text(language.title)
//            Spacer()
//            if language.language == selectedLanguage {
//                Image(systemName: "checkmark").foregroundColor(.accentColor)
//            }
//        }.contentShape(Rectangle()).onTapGesture {
//            self.selectedLanguage = self.language.language
//        }
//    }
//}
//
//struct SelectLanguageUI: View {
//    let lang: ProfileLang
//    let langs: [LangInfo]
//
//    @State var selectedLanguage: Language = UserSettings.shared.currentLanguage
//
//    init(lang: ProfileLang) {
//        self.lang = lang
//        self.langs = [
//            LangInfo(language: Language.se, title: lang.swedish),
//            LangInfo(language: Language.fi, title: lang.finnish),
//            LangInfo(language: Language.en, title: lang.english)
//        ]
//    }
//
//    var body: some View {
//        List {
//            ForEach(langs, id: \.title) { item in
//                LanguageCell(language: item, selectedLanguage: self.$selectedLanguage)
//            }
//        }.navigationBarTitle(lang.language)
//    }
//}
