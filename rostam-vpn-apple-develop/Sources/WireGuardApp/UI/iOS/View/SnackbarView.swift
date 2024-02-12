// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftMessages

class SnackbarView: BaseView, Identifiable {
    var id: String

    let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()

    init(message: String, icon: String, id: String?) {
        self.id = id ?? UUID().uuidString
        super.init(frame: CGRect.zero)

        label.text = message
        imageView.image = UIImage(named: icon)

        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24.0),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15.0),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24.0),
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 36.0),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -36.0)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
