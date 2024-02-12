// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class AboutViewController: SubpageViewController {
    let aboutRostamTextView: UITextView = {
        let aboutRostamTextView = UITextView()
        aboutRostamTextView.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        aboutRostamTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        aboutRostamTextView.textColor = UIColor.charcoalGrey
        aboutRostamTextView.textAlignment = .right
        aboutRostamTextView.isEditable = false
        aboutRostamTextView.isScrollEnabled = true
        aboutRostamTextView.alwaysBounceVertical = false
        aboutRostamTextView.backgroundColor = .white
        aboutRostamTextView.text = tr("aboutRostamText")
        aboutRostamTextView.dataDetectorTypes = UIDataDetectorTypes.link
        let linkTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.camel,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        aboutRostamTextView.linkTextAttributes = linkTextAttributes
        aboutRostamTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return aboutRostamTextView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(aboutRostamTextView)
        aboutRostamTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aboutRostamTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aboutRostamTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aboutRostamTextView.topAnchor.constraint(equalTo: view.topAnchor),
            aboutRostamTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        restorationIdentifier = "AboutVC"
    }
}
