import Foundation
import UIKit

class StatCell: BoatCell {
    static let identifier = String(describing: StatCell.self)
    
    let titleLabel = BoatLabel.build(alignment: .left, numberOfLines: 0)
    let statLabel = BoatLabel.build(alignment: .left, numberOfLines: 0)
    
    override func configureView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(statLabel)
        statLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.width.equalTo(100)
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
        }
    }
    
    func fill(kv: LabeledValue) {
        fill(label: kv.label, value: kv.value)
    }
    
    func fill(label: String, value: CustomStringConvertible) {
        titleLabel.text = label
        statLabel.text = value.description
    }
}
