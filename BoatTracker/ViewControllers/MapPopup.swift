//
//  MapPopup.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 5.12.2021.
//  Copyright © 2021 Michael Skogberg. All rights reserved.
//

import Foundation

class MapPopup: UIViewController {
    let child: UIView
    
    init(child: UIView) {
        self.child = child
        super.init(nibName: nil, bundle: nil)
        //presentationController?.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelClicked(_:)))
        view.addSubview(child)
        view.backgroundColor = BoatColors.shared.backgroundColor
        child.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        // Hack to make content fit in the compressed popover size even when some text content takes more than one line.
        // Looks quite good also when all text is on one line since the title is then separated from the rest of the content.
        let extraHeight: CGFloat = 30
        preferredContentSize = CGSize(width: size.width, height: size.height + extraHeight)
    }
    
    @objc func cancelClicked(_ sender: UIBarButtonItem) {
        goBack()
    }
}
