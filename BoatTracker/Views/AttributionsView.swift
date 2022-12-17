import Foundation
import UIKit
import SwiftUI

struct AttributionView: View {
    let data: AppAttribution
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.title)
                .frame(maxWidth: .infinity)
            if let text = data.text {
                Spacer().frame(height: margin.medium)
                Text(text)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
            Spacer().frame(height: margin.medium)
            ForEach(data.links, id: \.url.absoluteString) { link in
                Link(destination: link.url) {
                    Text(link.text)
                        .font(.system(size: 14))
                        .padding(margin.small)
                        .padding(.horizontal, margin.small)
                        .background(.gray.opacity(0.3))
                }
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
            }
            Divider().padding(.top)
        }
    }
}

struct AttributionsView: View {
    let info: AttributionInfo
    var attributions: [AppAttribution] { info.attributions }
    var body: some View {
        BoatList {
            ForEach(attributions) { attribution in
                AttributionView(data: attribution)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(info.title)
    }
}

struct AttributionsViewPreviews: PreviewProvider {
    static var attrs = [
        AppAttribution(title: "Attribution 1 very long title", text: "Good library", links: [TextAndUrl(text: "Go here", url: URL(string: "https://www.google.com")!)]),
        AppAttribution(title: "Attribution 2", text: "Excellent library yeah here we go", links: [TextAndUrl(text: "Link", url: URL(string: "https://www.google.com")!)]),
        AppAttribution(title: "Attribution 3", text: nil, links: [TextAndUrl(text: "Link 3", url: URL(string: "https://www.google.com")!)])
    ]
    static var previews: some View {
        Group {
            AttributionsView(info: AttributionInfo(title: "Attributions",
                                                   attributions: attrs))
        }
    }
}
