// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class BottomSheetCollapsedView: UIView {
    var onExpand: (() -> Void)?

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont(name: "NunitoSans-Regular", size: 16.0)
        title.numberOfLines = 0
        title.textColor = UIColor.brownGrey
        title.text = tr("turnVpnOffToChooseServerLocation")
        return title
    }()

    let flagImage: UIImageView = {
        let flagImage = UIImageView()
        return flagImage
    }()

    let serverNameLabel: UILabel = {
        let serverNameLabel = UILabel()
        serverNameLabel.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        serverNameLabel.numberOfLines = 0
        serverNameLabel.textColor = .white
        return serverNameLabel
    }()

    let chevronUp: UIImageView = {
        let chevronUp = UIImageView()
        chevronUp.image = UIImage(named: "iconChevronUp")
        chevronUp.tintColor = .white
        return chevronUp
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        let selectedRegion = RegionManager.shared.getSelectedRegion()
        serverNameLabel.text = tr(selectedRegion)
        let flag = UIImage(named: "flag_\(selectedRegion)")
        flagImage.image = flag

        self.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30.0),
            title.topAnchor.constraint(equalTo: self.topAnchor, constant: 11.0)
        ])

        self.addSubview(flagImage)
        flagImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flagImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 39.0),
            flagImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25.0),
            flagImage.widthAnchor.constraint(equalToConstant: 35.0),
            flagImage.heightAnchor.constraint(equalToConstant: 35.0)
        ])

        self.addSubview(serverNameLabel)
        serverNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            serverNameLabel.leadingAnchor.constraint(equalTo: flagImage.trailingAnchor, constant: 11.0),
            serverNameLabel.centerYAnchor.constraint(equalTo: flagImage.centerYAnchor)
        ])

        self.addSubview(chevronUp)
        chevronUp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chevronUp.centerYAnchor.constraint(equalTo: flagImage.centerYAnchor),
            chevronUp.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -28.0),
            chevronUp.widthAnchor.constraint(equalToConstant: 32.0),
            chevronUp.heightAnchor.constraint(equalToConstant: 32.0)
        ])

        chevronUp.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChevronUpTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        chevronUp.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func onChevronUpTapped() {
        onExpand?()
    }
}
