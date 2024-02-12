// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftMessages
import Amplitude

class DigitalSafetySnackbarView: BaseView {
    var title: String
    var shortDescription: String
    var link: String

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "iconInfo")
        return imageView
    }()

    let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.font = UIFont(name: "NunitoSans-Bold", size: 20.0)
        headerLabel.numberOfLines = 0
        headerLabel.textColor = .white
        headerLabel.text = tr("digitalSafetyTipTitle")
        return headerLabel
    }()

    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "NunitoSans-Bold", size: 16.0)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .white
        return titleLabel
    }()

    let shortDescriptionLabel: UILabel = {
        let shortDescriptionLabel = UILabel()
        shortDescriptionLabel.font = UIFont(name: "NunitoSans-Regular", size: 16.0)
        shortDescriptionLabel.numberOfLines = 0
        shortDescriptionLabel.textColor = .white
        return shortDescriptionLabel
    }()

    let readMoreLabel: UILabel = {
        let readMoreLabel = UILabel()
        readMoreLabel.font = UIFont(name: "NunitoSans-Regular", size: 16.0)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        let attributedText = NSMutableAttributedString(string: tr("digitalSafetyTipReadMore"),
                                                      attributes: attributes)
        readMoreLabel.attributedText = attributedText
        return readMoreLabel
    }()

    init(title: String, shortDescription: String, link: String) {
        self.title = title
        self.shortDescription = shortDescription
        self.link = link
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.snackbarInfo
        titleLabel.text = self.title
        shortDescriptionLabel.text = self.shortDescription

        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24.0),
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 36.0),
            imageView.widthAnchor.constraint(equalToConstant: 32.0),
            imageView.heightAnchor.constraint(equalToConstant: 32.0)
        ])

        self.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15.0),
            headerLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            headerLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 36.0)
        ])

        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            titleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10.0)
        ])

        self.addSubview(shortDescriptionLabel)
        shortDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shortDescriptionLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            shortDescriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            shortDescriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor)
        ])

        self.addSubview(readMoreLabel)
        readMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            readMoreLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            readMoreLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            readMoreLabel.topAnchor.constraint(equalTo: shortDescriptionLabel.bottomAnchor, constant: 10.0),
            readMoreLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -36.0)
        ])

        readMoreLabel.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(readMoreLabelTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        readMoreLabel.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func readMoreLabelTapped() {
        if let url = URL(string: self.link) {
            UIApplication.shared.open(url)

            let eventProperties = ["url": url as Any]
            Amplitude.instance().logEvent("Digital safety tip opened", withEventProperties: eventProperties)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
