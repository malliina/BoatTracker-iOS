import Foundation
import SwiftUI
import UIKit

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

struct AttributionsViewPreviews: BoatPreviewProvider, PreviewProvider {
  static var preview: some View {
    AttributionsView(info: lang.attributions)
  }
}
