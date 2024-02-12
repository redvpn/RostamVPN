// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class SocialMediaView: UIView {
    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont(name: "NunitoSans-Bold", size: 20.0)
        title.numberOfLines = 0
        title.textColor = UIColor.black
        title.text = tr("followRostamVpn")
        return title
    }()

    let twitterIcon: UIImageView = {
        let twitterIcon = UIImageView()
        twitterIcon.image = UIImage(named: "iconTwitter")!.withRenderingMode(.alwaysTemplate)
        twitterIcon.tintColor = UIColor.black
        twitterIcon.isUserInteractionEnabled = true
        return twitterIcon
    }()

    let instagramIcon: UIImageView = {
        let instagramIcon = UIImageView()
        instagramIcon.image = UIImage(named: "iconInstagram")!.withRenderingMode(.alwaysTemplate)
        instagramIcon.tintColor = UIColor.black
        instagramIcon.isUserInteractionEnabled = true
        return instagramIcon
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        self.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: self.topAnchor),
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])

        self.addSubview(twitterIcon)
        twitterIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            twitterIcon.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 23.0),
            twitterIcon.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])

        self.addSubview(instagramIcon)
        instagramIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instagramIcon.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 23.0),
            instagramIcon.leadingAnchor.constraint(equalTo: twitterIcon.trailingAnchor, constant: 16.0)
        ])

        let twitterTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(twitterIconTapped))
        twitterTapGestureRecognizer.numberOfTapsRequired = 1
        twitterIcon.addGestureRecognizer(twitterTapGestureRecognizer)

        let instagramTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(instagramIconTapped))
        instagramTapGestureRecognizer.numberOfTapsRequired = 1
        instagramIcon.addGestureRecognizer(instagramTapGestureRecognizer)
    }

    @objc func twitterIconTapped() {
        openUrl(urlPath: tr("twitterUrl"))
    }

    @objc func instagramIconTapped() {
        openUrl(urlPath: tr("instagramUrl"))
    }

    private func openUrl(urlPath: String) {
        let url = NSURL(string: urlPath)! as URL

        if #available(iOS 10, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
