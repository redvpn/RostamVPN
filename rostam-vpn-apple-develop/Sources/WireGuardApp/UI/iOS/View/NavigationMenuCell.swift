// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class NavigationMenuCell: UITableViewCell {
    let iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.tintColor = UIColor.primaryDark
        return iconImageView
    }()

    let menuLabel: UILabel = {
        let menuLabel = UILabel()
        menuLabel.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        menuLabel.textColor = UIColor.primaryDark
        menuLabel.textAlignment = .right
        return menuLabel
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedBackgroundView = UIView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24.0),
            iconImageView.widthAnchor.constraint(equalToConstant: 24.0),
            iconImageView.heightAnchor.constraint(equalToConstant: 24.0)
        ])

        contentView.addSubview(menuLabel)
        menuLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            menuLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15.0)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if #available(iOS 14.0, *) {
            self.contentView.backgroundColor = selected ? UIColor.cameoSilk : .white
        } else {
            self.selectedBackgroundView!.backgroundColor = selected ? UIColor.cameoSilk : .white
        }
        menuLabel.textColor = selected ? UIColor.camel : UIColor.primaryDark
        iconImageView.tintColor = selected ? UIColor.camel : UIColor.primaryDark
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if #available(iOS 14.0, *) {
            self.contentView.backgroundColor = highlighted || self.isSelected ? UIColor.cameoSilk : .white
        } else {
            self.selectedBackgroundView!.backgroundColor = highlighted || self.isSelected ? UIColor.cameoSilk : .white
        }
        menuLabel.textColor = highlighted || self.isSelected ? UIColor.camel : UIColor.primaryDark
        iconImageView.tintColor = highlighted || self.isSelected ? UIColor.camel : UIColor.primaryDark
    }
}
