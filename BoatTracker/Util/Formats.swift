//
//  Formats.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 02/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class Formats {
    static let shared = Formats()
    
    private var formatters: [FormatsLang: Formatter] = [:]
    
    func date(date: Date, lang: FormatsLang) -> String {
        return find(lang).date(date: date)
    }
    
    func dateTime(millis: UInt64, lang: FormatsLang) -> String {
        return dateTime(date: Date(timeIntervalSince1970: Double(millis) / 1000), lang: lang)
    }
    
    func dateTime(date: Date, lang: FormatsLang) -> String {
        return find(lang).dateTime(date: date)
    }
    
    private func find(_ lang: FormatsLang) -> Formatter {
        guard let formatter = formatters[lang] else {
            let fmt = Formatter(conf: lang)
            formatters.updateValue(Formatter(conf: lang), forKey: lang)
            return fmt
        }
        return formatter
    }
}

class Formatter {
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter
    
    init(conf: FormatsLang) {
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = conf.date
        
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.dateFormat = conf.time
        
        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = conf.dateTime
    }
    
    func date(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func time(date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    func dateTime(date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }
}
