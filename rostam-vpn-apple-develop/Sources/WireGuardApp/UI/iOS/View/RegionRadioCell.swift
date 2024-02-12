// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class RegionRadioCell: UITableViewCell {
    let flagImageView: UIImageView = {
        let flagImageView = UIImageView()
        return flagImageView
    }()

    let regionLabel: UILabel = {
        let regionLabel = UILabel()
        regionLabel.font = UIFont(name: "NunitoSans-Regular", size: 20.0)
        regionLabel.numberOfLines = 1
        regionLabel.textColor = .white
        regionLabel.textAlignment = .right
        return regionLabel
    }()

    let radioImageView: UIImageView = {
        let radioImageView = UIImageView()
        return radioImageView
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.backgroundColor = UIColor.primaryDark

        contentView.addSubview(flagImageView)
        flagImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flagImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            flagImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18.5),
            flagImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.5),
            flagImageView.widthAnchor.constraint(equalToConstant: 36.0),
            flagImageView.heightAnchor.constraint(equalToConstant: 36.0)
        ])

        contentView.addSubview(regionLabel)
        regionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            regionLabel.centerYAnchor.constraint(equalTo: flagImageView.centerYAnchor),
            regionLabel.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: 17.0)
        ])

        contentView.addSubview(radioImageView)
        radioImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radioImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            radioImageView.centerYAnchor.constraint(equalTo: flagImageView.centerYAnchor),
            radioImageView.widthAnchor.constraint(equalToConstant: 34.0),
            radioImageView.heightAnchor.constraint(equalToConstant: 34.0)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let imageName = selected ? "radioChecked" : "radioUnchecked"
        radioImageView.image = UIImage(named: imageName)
        regionLabel.textColor = selected ? .white : regionLabel.textColor
    }
}
