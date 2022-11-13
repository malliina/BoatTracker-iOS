import Foundation
import UIKit
import SwiftUI

struct AttributionsRepresentable: UIViewControllerRepresentable {
    let info: AttributionInfo
    func makeUIViewController(context: Context) -> AttributionsVC {
        AttributionsVC(info: info)
    }
    
    func updateUIViewController(_ uiViewController: AttributionsVC, context: Context) {
        
    }
    
    typealias UIViewControllerType = AttributionsVC
}

struct AttributionsView: View {
    let info: AttributionInfo
    var attributions: [AppAttribution] { info.attributions }
    var body: some View {
        List {
            ForEach(attributions) { attribution in
                AttributionView(data: attribution)
            }
        }
        .listStyle(.plain)
    }
}

class AttributionsVC: BaseTableVC {
    let attributionKey = "AttributionCell"
    
    let info: AttributionInfo
    var attributions: [AppAttribution] { return info.attributions }
    
    init(info: AttributionInfo) {
        self.info = info
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = info.title
        tableView?.register(AppAttributionCell.self, forCellReuseIdentifier: attributionKey)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attribution = attributions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: attributionKey, for: indexPath)
        if let cell = cell as? AppAttributionCell {
            cell.fill(with: attribution)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributions.count
    }
}

struct AppAttribution: Codable {
    let title: String
    let text: String?
    let links: [Link]
}

extension AppAttribution: Identifiable {
    var id: String { title }
}

struct AttributionInfo: Codable {
    let title: String
    let attributions: [AppAttribution]
}

class Link: NSObject, Codable {
    let text: String
    let url: URL
    
    init(text: String, url: URL) {
        self.text = text
        self.url = url
    }
}
