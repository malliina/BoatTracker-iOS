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

class AppAttributionCell: BoatCell {
    var title: UILabel? = nil
    var subTitle: UILabel? = nil
    var links: [UIButton] = []
    
    var data: AppAttribution? = nil
    
    override func configureView() {
    }
    
    func fill(with data: AppAttribution) {
        self.data = data
        if title == nil {
            let titleLabel = BoatLabel.build(text: data.title)
            title = titleLabel
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(spacing)
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.trailing.equalTo(contentView.snp.trailingMargin)
            }
        }
        if let text = data.text, let title = title {
            if subTitle == nil {
                let subLabel = BoatLabel.build(text: text)
                subTitle = subLabel
                contentView.addSubview(subLabel)
                subLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(title)
                    make.top.equalTo(title.snp.bottom).offset(spacing)
                }
            }
        }
        data.links.enumerated().forEach { (offset, link) in
            let exists = links.indices.contains(offset)
            guard let viewAbove = offset == 0 ? subTitle ?? title : links[offset-1] else { return }
            if !exists {
                let btn = BoatButton.nav(title: link.text, fontSize: 14)
                contentView.addSubview(btn)
                links.append(btn)
                btn.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(viewAbove)
                    make.top.equalTo(viewAbove.snp.bottom).offset(spacing)
                    let isLast = offset == data.links.count - 1
                    if isLast {
                        make.bottom.equalTo(contentView.snp.bottom).inset(spacing)
                    }
                }
                btn.addTarget(self, action: #selector(linkClicked(_:)), for: .touchUpInside)
            }
        }
    }
    
    @objc func linkClicked(_ sender: UIButton) {
        guard let idx = links.firstIndex(of: sender) else { return }
        guard let url = data?.links[idx].url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
