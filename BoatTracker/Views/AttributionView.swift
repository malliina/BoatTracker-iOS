import Foundation
import UIKit
import SwiftUI

struct AttributionView: View {
    let data: AppAttribution
    var body: some View {
        VStack(alignment: .center) {
            Text(data.title)
            if let text = data.text {
                Spacer().frame(height: 12)
                Text(text)
                    .multilineTextAlignment(.center)
            }
            Spacer().frame(height: 12)
            ForEach(data.links, id: \.url.absoluteString) { link in
                Button {
                    UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
                } label: {
                    Text(link.text)
                        .font(.system(size: 14))
                        .background(Color(uiColor: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)))
                }
                .cornerRadius(20)
            }
        }.frame(maxWidth: .infinity)
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
