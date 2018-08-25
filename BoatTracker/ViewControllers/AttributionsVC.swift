//
//  AttributionsVC.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 12/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit

class AttributionsVC: BaseTableVC {
    let attributionKey = "AttributionCell"
    let linksKey = "LinkCell"
    
    let maps = Attribution(title: "Maritime data",
                text: "Source: Finnish Transport Agency. Not for navigational use. Does not meet the requirements for official nautical charts.",
                link: Link(text: "CC 4.0", url: URL(string: "https://creativecommons.org/licenses/by/4.0/")!))
    let marineApi = LinksAttribution(title: "Java Marine API",
                     link1: Link(text: "GNU LGPL",
                                 url: URL(string: "http://www.gnu.org/licenses/lgpl-3.0-standalone.html")!),
                     link2: Link(text: "Java Marine API",
                                 url: URL(string: "https://ktuukkan.github.io/marine-api/")!))
    let fontAwesome = Attribution(title: "Font Awesome", text: nil, link: Link(text: "https://fontawesome.com/license", url: URL(string: "https://fontawesome.com/license")!))
    let openIconic = Attribution(title: "Open Iconic", text: nil, link: Link(text: "https://github.com/iconic/open-iconic", url: URL(string: "https://github.com/iconic/open-iconic")!))
    let poiju = Attribution(title: "Inspiration", text: nil, link: Link(text: "POIJU.IO", url: URL(string: "https://github.com/iaue/poiju.io")!))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Attributions"
        tableView?.register(AttributionCell.self, forCellReuseIdentifier: attributionKey)
        tableView?.register(LinksAttributionCell.self, forCellReuseIdentifier: linksKey)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.row == 1 ? linksCell(indexPath: indexPath) : attributionCell(indexPath: indexPath)
        cell.selectionStyle = .none
        return cell
    }
    
    func linksCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: linksKey, for: indexPath)
        if let cell = cell as? LinksAttributionCell {
            cell.fill(with: marineApi)
        }
        return cell
    }
    
    func attributionCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: attributionKey, for: indexPath)
        if let cell = cell as? AttributionCell, let attribution = attribution(for: indexPath) {
            cell.fill(with: attribution)
        }
        return cell
    }
    
    func attribution(for indexPath: IndexPath) -> Attribution? {
        switch indexPath.row {
        case 0: return maps
        case 2: return fontAwesome
        case 3: return openIconic
        case 4: return poiju
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

struct Attribution {
    let title: String
    let text: String?
    let link: Link
}

struct LinksAttribution {
    let title: String
    let link1: Link
    let link2: Link
}

struct Link {
    let text: String
    let url: URL
}
