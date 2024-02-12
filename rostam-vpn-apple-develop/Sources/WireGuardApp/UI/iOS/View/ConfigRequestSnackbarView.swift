// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftMessages

class ConfigRequestSnackbarView: BaseView {
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "iconError")
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        label.numberOfLines = 0
        label.textColor = .white
        label.text = tr("vpnConnectionFailure")
        return label
    }()

    let mailToLabel: UILabel = {
        let mailToLabel = UILabel()
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.foregroundColor: UIColor.camel
        ]
        let attributedText = NSAttributedString(string: tr("configRequestEmail"),
                                                      attributes: attributes)
        mailToLabel.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        mailToLabel.numberOfLines = 0
        mailToLabel.attributedText = attributedText
        mailToLabel.textAlignment = .left
        return mailToLabel
    }()

    init() {
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.snackbarError

        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24.0),
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 36.0)
        ])

        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15.0),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 36.0)
        ])

        self.addSubview(mailToLabel)
        mailToLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mailToLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            mailToLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10.0),
            mailToLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -36.0)
        ])

        mailToLabel.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mailToLabelTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        mailToLabel.addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func mailToLabelTapped() {
        let email = tr("configRequestEmail")
        let subject = tr("configRequestSubject")
        let publicKeyBase64 = KeyStore.shared.publicKey?.base64Key
        let body = tr("configRequestBody").replacingOccurrences(of: "PUBKEY", with: publicKeyBase64!)
        if let gmailUrl = getMailToUrl(scheme: "googlegmail", to: email, subject: subject, body: body) {
            if UIApplication.shared.canOpenURL(gmailUrl) {
                UIApplication.shared.open(gmailUrl)
            } else {
                if let mailUrl = getMailToUrl(scheme: "mailto", to: email, subject: subject, body: body) {
                    UIApplication.shared.open(mailUrl)
                }
            }
        }
    }

    private func getMailToUrl(scheme: String, to: String, subject: String, body: String) -> URL? {
        let mailTo = scheme == "googlegmail" ? "\(scheme)://co?to=\(to)&subject=\(subject)&body=\(body)" : "\(scheme)://\(to)?subject=\(subject)&body=\(body)"
        let url = URL(string: mailTo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)

        return url
    }
}
